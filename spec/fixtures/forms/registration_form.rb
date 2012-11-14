class RegistrationForm < Redtape::Form
  validates_and_saves :user

  attr_accessor :first_name, :last_name

  def populate
    self.user = User.new(:name => "#{first_name} #{last_name}")
  end
end
