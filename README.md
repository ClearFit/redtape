# Redtape  [![Build Status](https://secure.travis-ci.org/ClearFit/redtape.png)](http://travis-ci.org/ClearFit/redtape)

Redtape provides an alternative to [ActiveRecord::NestedAttributes#accepts_nested_attributes_for](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for) in the form of, well, a Form!  The initial implementation was heavily inspired by ["7 Ways to Decompose Fat Activerecord Models"](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) by [Bryan Helmkamp](https://github.com/brynary).

In a nutshell, `accepts_nested_attributes_for` tightly couples your View to your Model.  This is highly undesirable as it makes both harder to maintain.  Instead, the Form provides a Controller delegate that mediates between the two, acting like an ActiveModel from the View and Controller's perspective but acting a proxy to the Model layer.

## Installation

Add this line to your application's Gemfile:

    gem 'redtape'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redtape

## Usage

To use Redtape, create a subclass of Redtape::Form

### Form class conventions

#### Call `#validates_and_saves`

This class method should be passed the underscored names of each "top level model" that this form will save.  For instance, say you have a `RegistrationForm` that wants to manage a User--and that User class has one Account.  You'd want your code to look like:

```ruby
class RegistrationForm < Redtape::Form
  validates_and_saves :user
end
```

Note that there is **no** mention of the Account class.  We handle that elsewhere in the Form subclass.

#### Add accessors to your *Form* for each form field

The subclass also needs an accessor for each form field that you wish to capture.  You can accomplish this with plain ol' `#attr_accessor` calls or, if you're feeling cute, you could use [Virtus](https://github.com/solnic/virtus) to provide more robust attribute definitions.

These accessors define the contract with the view.  The fields are expected to be supplied (or optionally not) by the view and no more.

#### Implement a `#populate` method

ActionPack will populate the `Form` just like it would any other `ActiveModel` object.  `#populate`  then finds or builds your User and Account objects using the values set on the accessors by ActionPack.

So say we have a RegistrationForm with these fields:


```ruby
class RegistrationForm < Redtape::Form
  validates_and_saves :user

  attr_accessor :first_name, :last_name, :email
end
```

... then your `#populate` method may look something like this:

```ruby
def populate
  name = "#{first_name} #{last_name}"

  user = User.joins(:account).where("accounts.email = ?", email).first
  if user
    user.account.name = name
  else
    account = Account.new(
      :name => name,
      :email => email
    )
    self.user = User.new(:account => account)
  end
end
```

#### Using the Form subclass

In your `#create` or `#update` methods, you'll want somthing like the following:

```ruby
def update
  @form = RegistrationForm.new(params[:registration_form]
  if @form.save
    # happy path
  else
    # sad path
  end
end
```

In your view, you ***should*** be able to get by just using the `Form` instance where you would normally use a view.

In some special cases, e.g., you're using [devise](https://github.com/plataformatec/devise) as we are, you may need something like this:

```erb
<%= form_for(@form, :as => resource_name, :url => registration_path(resource_name)) do |f| %>
<% end %>
```

#### That's it!

For this example, what you're left with is something like:

```ruby
class RegistrationForm < Redtape::Form
  validates_and_saves :user

  attr_accessor :first_name, :last_name, :email

  def populate
    name = "#{first_name} #{last_name}"

    user = User.joins(:account).where("accounts.email = ?", email).first
    if user
      user.account.name = name
    else
      account = Account.new(
        :name => name,
        :email => email
      )
      self.user = User.new(:account => account)
    end
  end
end
```

Redtape will use your model's/models' validations to determine if the form data is correct.  That is, you validate and save the same way you would with any `ActiveModel`.  If any of the models are invalid, errors are added to the `Form` for handling within the View/Controller.

## What's left

We'd really like to add the following to make Redtape even easier for folks to plug n' play:

* Map ActiveRecord errors (validation failures) to the matching form field
* A Rails generator to add the app/forms and (test/spec)/forms directories
* Handling of <object>_id params to further automate updates via forms
* Cleaner handling of errors within nested objects

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Finally, we'd really like your feedback
