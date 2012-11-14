class AutomatedRegistrationForm < Redtape::Form
  validates_and_saves :user

  nested_accessible_attrs [
    :name,
    :addresses => [
      :address1,
      :address2,
      :city,
      :state,
      :zipcode
    ]
  ]
end
