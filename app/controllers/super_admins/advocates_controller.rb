class SuperAdmins::AdvocatesController < ApplicationController

  include PasswordHelpers

  before_action :set_chamber,   only: [:show, :index, :edit, :update, :new, :create, :change_password, :update_password]
  before_action :set_advocate,  only: [:show, :edit, :update, :change_password, :update_password]

  def show; end

  def index
    @advocates = Advocate.where(chamber: @chamber)
  end

  def new
    @advocate = Advocate.new(chamber: @chamber)
    @advocate.build_user
  end

  def create
    @advocate = Advocate.new(params_with_temporary_password.merge(chamber: @chamber))

    if @advocate.save
      @advocate.user.send_reset_password_instructions
      redirect_to super_admins_chamber_advocate_path(@chamber, @advocate), notice: 'Advocate successfully created'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @advocate.update(advocate_params)
     redirect_to super_admins_chamber_advocate_path(@chamber,@advocate), notice: 'Advocate successfully updated'
    else
      render :edit
    end
  end

  def change_password; end

  # NOTE: do NOT use update_password in PasswordHelper as it will
  #       require current password and then sign in as user whose
  #       password was changed and redirect to their user profile path
  def update_password
    user = @advocate.user

    if user.update(password_params[:user_attributes])
      redirect_to super_admins_chamber_advocate_path(@chamber,@advocate), notice: 'Advocate password successfully updated'
    else
      render :change_password
    end
  end

  private

  def advocate_params
    params.require(:advocate).permit(
     :role,
     :apply_vat,
     :supplier_number,
     user_attributes: [:id, :email, :email_confirmation, :password, :password_confirmation, :first_name, :last_name]
    )
  end

  def set_advocate
    @advocate  = Advocate.find(params[:id])
  end

  def set_chamber
    @chamber = Chamber.find(params[:chamber_id])
  end

end
