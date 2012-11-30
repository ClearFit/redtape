# Redtape  [![Build Status](https://secure.travis-ci.org/ClearFit/redtape.png)](http://travis-ci.org/ClearFit/redtape)

Redtape provides an alternative to [ActiveRecord::NestedAttributes#accepts_nested_attributes_for](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for) in the form of, well, a Form!  The initial implementation was heavily inspired by ["7 Ways to Decompose Fat Activerecord Models"](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) by [Bryan Helmkamp](https://github.com/brynary).

In a nutshell, `accepts_nested_attributes_for` tightly couples your View to your Model.  This is highly undesirable as it makes both harder to maintain.  Instead, the Form provides a Controller delegate that mediates between the two, acting like an ActiveModel from the View and Controller's perspective but acting a proxy to the Model layer.

## Features

* Automatically converting nested form data into the appropriate ActiveRecord object graph
* Optional dependency injection of a data mapper to map form fields to ActiveRecord object fields
* Optional form data whitelisting

## Installation

Add this line to your application's Gemfile:

    gem 'redtape'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redtape

## Usage

To use Redtape, you use a *Redtape::Form* in your controller and your nested *form_for*s where you would supply an ActiveRecord object.

A *Redtape::Form* is simply an ActiveModel.  So you just call *#save*, *#valid?*, and *#errors* on it like any other ActiveModel.

Redtape will use your model's/models' validations to determine if the form data is correct.  That is, you validate and save the same way you would with any `ActiveModel`.  If any of the models are invalid, errors are added to the `Form` for handling within the View/Controller.

Using a *Redtape::Form* goes something like this:

```html
<%= form_for @form, :as => :whatever %>
...
```

```ruby
class SomethingController
  def new
    @form = Redtape::Form.new(self, params)
  end

  def create # should support update as well...
    @form = Redtape::Form.new(self, params)
    if @form.save
      # ...
    else
      # ...
    end
  end
end
```

### If you want to get to the AR object directory...

Call *#model* thusly on your *Redtape::Form* instance:

```ruby
  @form = Redtape::Form.new(self, params)
  @form.model
```

### If your controller name doesn't map directly to the form's ActiveRecord class...

You just add an argument:

```ruby
class SomethingController
  def create
    @form = Redtape::Form.new(self, params, :top_level_name => :user)
    # ...
  end
```

### (Optional) Custom form field mapping to ActiveRecord objects

A Redtape "data mapper" is just a class that implements a *#populated\_individual\_record* method such as:

```ruby
module NestedFormRedtape
  def populate_individual_record(record, attrs)
    if record.is_a?(User)
      record.name = "#{attrs[:first_name]} #{attrs[:last_name]}"
    elsif record.is_a?(Address)
      record.attributes = record.attributes.merge(attrs)
    end
  end
end
```
Yes, we are branching on classes. Yes, this usually is a smell to use polymorphism. In this case, the average data mapper is going to be pretty simple.  As such, I didn't find this to be onerous.

To use this custom data mapper, just mix it into your controller.  Redtape detects the presence of your method and uses it instead of the default implementation.

I tend to implement these as modules to simplify testing.  I create an object that I nominally call a "\*Controller", mix in the module, and stub out a *#params* method. This gives me something close enough to a controller for testing while not requiring instantiating a real Rails Controller.  For examples, see the spec directory.


### Optional whitelisting

This should like familiar to anyone who has used the *:include* option on an ActiveRecord finder.

```ruby
  Redtape::Form.new(self, params, :whitelisted_attrs => {
    :user => [
      :name,
      { :phone_number => [ :country_code, :area_code, :number ] },
      { :addresses => [:address1, :address2, :city, :state, :zipcode] }
    ]
  }
```

Currently, if a whitelist validation occurs, a Redtape::WhitelistValidationError is raised containing a detailed error message of violating parameters.  I figured you'd like to know

## What's left

We'd really like to add the following to make Redtape even easier for folks to plug n' play:

* A Rails generator to add the app/forms and (test/spec)/forms directories

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Finally, we'd really like your feedback
