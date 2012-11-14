class Everything < ActiveRecord::Migration
  def change
    create_table :users do |u|
      u.string :name
      u.string :social_security_number
      u.timestamps
    end

    create_table :addresses do |a|
      a.string :address1
      a.string :address2
      a.string :city
      a.string :state
      a.string :zipcode
      a.string :alarm_code
      a.integer :user_id
    end
  end
end
