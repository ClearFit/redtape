class CreatePhoneNumber < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |p|
      p.string :country_code
      p.string :area_code
      p.string :number
      p.integer :user_id
      p.timestamps
    end
  end
end
