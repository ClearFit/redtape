class RegistrationForm < Redtape::Form
  validates_and_saves :user

  attr_accessor :first_name, :last_name

  def populate(params_subset, model)
    model.name = "#{params_subset[:first_name]} #{params_subset[:last_name]}"

    model
  end
end
