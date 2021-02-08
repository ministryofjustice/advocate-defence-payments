# == Schema Information
#
# Table name: documents
#
#  id                                      :integer          not null, primary key
#  claim_id                                :integer
#  created_at                              :datetime
#  updated_at                              :datetime
#  document_file_name                      :string
#  document_content_type                   :string
#  document_file_size                      :integer
#  document_updated_at                     :datetime
#  external_user_id                        :integer
#  converted_preview_document_file_name    :string
#  converted_preview_document_content_type :string
#  converted_preview_document_file_size    :integer
#  converted_preview_document_updated_at   :datetime
#  uuid                                    :uuid
#  form_id                                 :string
#  creator_id                              :integer
#  verified_file_size                      :integer
#  file_path                               :string
#  verified                                :boolean          default(FALSE)
#

class Document < ApplicationRecord
  include DocumentAttachment
  include Duplicable

  belongs_to :external_user
  belongs_to :creator, class_name: 'ExternalUser'
  belongs_to :claim, class_name: 'Claim::BaseClaim'

  validates_attachment :document,
                       presence: { message: 'Document must have an attachment' },
                       size: { in: 0.megabytes..20.megabytes },
                       content_type: {
                         content_type: ['application/pdf',
                                        'application/msword',
                                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                        'application/vnd.oasis.opendocument.text',
                                        'text/rtf',
                                        'application/rtf',
                                        'image/jpeg',
                                        'image/png',
                                        'image/tiff',
                                        'image/bmp',
                                        'image/x-bitmap']
                       }

  alias attachment document # to have a consistent interface to both Document and Message
  delegate :provider_id, to: :external_user

  before_save :generate_pdf_tmpfile
  before_save :add_converted_preview_document
  before_save :create_checksum

  validate :documents_count

  # TODO: Remove after moving to Active Storage
  def create_checksum
    return if document_file_name.nil?

    %w[document converted_preview_document].each do |name|
      io = Paperclip.io_adapters.for(send(name))
      next if io.nil?

      send("as_#{name}_checksum=", Digest::MD5.new.tap do |checksum|
        while (chunk = io.read(5.megabytes))
          checksum << chunk
        end

        io.rewind
      end.base64digest)
    rescue Errno::ENOENT
      send("as_#{name}_checksum=", nil)
    end
  end

  def copy_from(original_doc, verify: false)
    self.document = original_doc.document
    verify ? save_and_verify : save
  end

  def save_and_verify
    result = save
    if result
      result = verify_and_log
    else
      transform_cryptic_paperclip_error
      log_save_error
    end
    result
  end

  def verify_and_log
    generate_log_stuff(:info, 'save', 'Document saved')
    if verify_file_exists
      generate_log_stuff(:info, 'verify', 'Document verified')
      result = true
    else
      generate_log_stuff(:error, 'verify_fail', 'Unable to verify document')
      errors[:document] << 'Unable to save the file - please retry' if verified_file_size&.zero?
      result = false
    end
    result
  end

  def log_save_error
    generate_log_stuff(:error, 'save_fail', 'Unable to save document')
  end

  private

  def generate_log_stuff(type, action, message)
    LogStuff.send(type,
                  :paperclip,
                  action: action,
                  document_id: id,
                  claim_id: claim_id,
                  filename: document_file_name, form_id: form_id) { message }
  end

  def verify_file_exists
    begin
      reloaded_file = reload_saved_file
      self.verified_file_size = File.stat(reloaded_file).size
      self.file_path = document.path
      self.verified = verified_file_size.positive?
      save!
    rescue StandardError => e
      errors[:document] << e.message
      self.verified = false
    end
    verified
  end

  def reload_saved_file
    Paperclip.io_adapters.for(document).path
  end

  def documents_count
    return true if form_id.nil?
    count = Document.where(form_id: form_id).count
    max_doc_count = Settings.max_document_upload_count
    return unless count >= max_doc_count
    errors.add(:document, "Total documents exceed maximum of #{max_doc_count}. This document has not been uploaded.")
  end

  def transform_cryptic_paperclip_error
    return unless errors[:document].include?('has contents that are not what they are reported to be')
    errors[:document].delete('has contents that are not what they are reported to be')
    errors[:document] << 'The contents of the file do not match the file extension'
  end
end
