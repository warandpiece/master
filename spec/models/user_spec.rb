require 'rails_helper'

RSpec.describe User, type: :model do
  it "FactoryGirl to create valid user" do 
    user = create(:user, email: "randomemail@email.com")

    expect(user).to be_valid
    expect(user.first_name).to eq("John")
  end
end