# Redtape

Redtape provides an alternative to [ActiveRecord::NestedAttributes#accepts\_nested\_attributes\_for](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for) as described in ["7 Ways to Decompose Fat Activerecord Models"](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) by [Bryan Helmkamp](https://github.com/brynary).

In a nutshell, *accepts\_nested\_attributes\_for* tightly couples your View to your Model.  This is highly undesirable as it makes both harder to maintain.  Instead, the Form provides a Controller delegate that mediates between the two, acting like an ActiveModel from the View and Controller's perspective but acting a proxy to the Model layer.

## Installation

Add this line to your application's Gemfile:

    gem 'redtape'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redtape

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
