/* global Dropzone, FormData, XMLHttpRequest */

moj.Modules.Dropzone = {
  init: function () {
    const self = this

    this.target = $('.dropzone')

    Dropzone.autoDiscover = false

    if (self.dragAndDropSupported() && self.formDataSupported() && self.fileApiSupported()) {
      this.target.addClass('dropzone-enhanced')
      self.setupDropzone()
      self.setupFileInput()
      self.setupStatusBox()
      $('.files').on('click', '.file-remove', $.proxy(this, 'onFileRemoveClick'))
    }
  },

  dragAndDropSupported: function () {
    const div = document.createElement('div')
    return typeof div.ondrop !== 'undefined'
  },

  formDataSupported: function () {
    return typeof FormData === 'function'
  },

  fileApiSupported: function () {
    const input = document.createElement('input')
    input.type = 'file'
    return typeof input.files !== 'undefined'
  },

  setupDropzone: function () {
    this.target.on('dragover', $.proxy(this, 'onDragOver'))
    this.target.on('dragleave', $.proxy(this, 'onDragLeave'))
    this.target.on('drop', $.proxy(this, 'onDrop'))
  },

  setupFileInput: function () {
    this.fileInput = this.target.find('[type=file]')
    this.fileInput.on('change', $.proxy(this, 'onFileChange'))
    this.fileInput.on('focus', $.proxy(this, 'onFileFocus'))
    this.fileInput.on('blur', $.proxy(this, 'onFileBlur'))
  },

  setupStatusBox: function () {
    this.status = $('<div aria-live="polite" role="status" class="govuk-visually-hidden" />')
    this.target.append(this.status)
  },

  toggleFileStatus: function () {
    $('.files tbody tr').length >= 1 ? $('.files').removeClass('hidden') : $('.files').addClass('hidden')
  },

  onFileChange: function (e) {
    this.status.html('Uploading files, please wait.')
    this.uploadFiles(e.currentTarget.files)
  },

  onFileRemoveClick: function (e) {
    e.preventDefault()
    const fileId = e.currentTarget.getAttribute('data-id')
    this.status.html('Removing file, please wait.')
    if (fileId) {
      $('#claim_document_ids_' + fileId).remove()
    } else {
      $(e.target).parent().parent().remove()
    }
    this.status.html('File removed.')
    this.toggleFileStatus()
  },

  onDragOver: function (e) {
    e.preventDefault()
    this.target.addClass('dropzone-dragover')
  },

  onDragLeave: function () {
    this.target.removeClass('dropzone-dragover')
  },

  onDrop: function (e) {
    e.preventDefault()
    this.target.removeClass('dropzone-dragover')
    this.status.html('Uploading files, please wait.')
    this.uploadFiles(e.originalEvent.dataTransfer.files)
  },

  onFileFocus: function (e) {
    this.target.find('label').addClass('dropzone-focused')
  },

  onFileBlur: function (e) {
    this.target.find('label').removeClass('dropzone-focused')
  },

  notificationHTML: function (fileName, fileStatus, fileStatusMsg, fileId) {
    let html = ''

    if (fileId) {
      html += '<tr id="document_' + fileId + '"><td>' + fileName + '</td>'
    } else {
      html += '<tr><td>' + fileName + '</td>'
    }

    html += '<td><span class="' + fileStatus + '">' + fileStatusMsg + '</span></td>'

    if (fileId) {
      html += '<td><a aria-label="Remove document: ' + fileName + '" class="file-remove" data-id="' + fileId + '" data-remote="true" data-method="delete" href="/documents/' + fileId + '" rel="nofollow">Remove</a></td></tr>'
    } else {
      html += '<td><a aria-label="Remove document: ' + fileName + '" class="file-remove" href="#dropzone-files" rel="nofollow">Remove</a></td>'
    }

    html += '</tr>'

    return html
  },

  createDocumentIdInput: function (id) {
    const input = '<input multiple="multiple" value="' + id + '" id="claim_document_ids_' + id + '" type="hidden" name="claim[document_ids][]"></input>'
    $('.document-ids').append(input)
  },

  uploadFiles: function (files) {
    for (let i = 0; i < files.length; i++) {
      if (files[i].size >= 20971520) {
        const tableBody = $('.files tbody')
        tableBody.append(this.notificationHTML(files[i].name, 'error', 'File is too big.'))
      } else {
        this.uploadFile(files[i])
      }
      this.toggleFileStatus()
    }
  },

  uploadFile: function (file) {
    const formData = new FormData()
    formData.append('document[document]', file)

    const tableBody = $('.files tbody')
    const tableRow = $('<tr><td><span class="file-name">' + file.name + '</span></td><td><progress value="0" max="100">0%</progress></td><td></td></tr>')
    tableBody.append(tableRow)

    const formId = $('#claim_form_id').val()
    formData.append('document[form_id]', formId)

    $.ajax({
      url: '/documents',
      type: 'post',
      data: formData,
      maxFilesize: 20,
      processData: false,
      contentType: false,

      success: $.proxy(function (response) {
        const fileName = response.document.document_file_name
        const fileId = response.document.id

        this.createDocumentIdInput(response.document.id)
        tableRow.replaceWith(this.notificationHTML(fileName, 'success', 'File has been uploaded.', fileId))
        this.status.html(response.document.document_file_name + ' has been uploaded.')
      }, this),

      error: $.proxy(function (xhr, status, error) {
        const fileName = file.name

        if (status === 'timeout') {
          tableRow.replaceWith(this.notificationHTML(fileName, 'error', 'The server failed to process your file.'))
          this.status.html('The server failed to process your file.')
        } else {
          tableRow.replaceWith(this.notificationHTML(fileName, 'error', xhr.responseJSON.error))
          this.status.html(fileName + ' ' + xhr.responseJSON.error)
        }
      }, this),

      xhr: function () {
        const xhr = new XMLHttpRequest()
        xhr.upload.addEventListener('progress', function (e) {
          if (e.lengthComputable) {
            let percentComplete = e.loaded / e.total
            percentComplete = parseInt(percentComplete * 100)
            tableRow.find('progress').prop('value', percentComplete).text(percentComplete + '%')
          }
        }, false)
        return xhr
      }
    })
  }

}
