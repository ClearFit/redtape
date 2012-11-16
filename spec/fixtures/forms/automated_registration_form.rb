class AutomatedRegistrationForm < Redtape::Form
  validates_and_saves :user
end
