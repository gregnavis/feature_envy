# Feature Envy

Feature Envy enhances Ruby with features found in other programming languages.

**WARNING**: This gem is still in development and a stable release hasn't been
made yet. Bug reports and contributions are welcome!

Supported features:

- Final classes
- Thread-safe lazy accessors
- Object literals
- Inspect (inspired by Elixir's `Kernel.inspect/2`)

## Installation

You can install the gem by running `gem install feature_envy` or adding it to
`Gemfile`:

```ruby
gem "feature_envy"
```

Don't forget to run `bundle install` afterwards.

## Usage

Below are example snippets for a quick start with the project. Please refer to
individual feature documentation for details. Features are designed to be
independent and should be enabled one-by-one.

### Final Classes

```ruby
module Models
  # Enable the feature in a given module via the using directive.
  using FeatureEnvy::FinalClass

  class Admin < User
    # Call final! inside the definition of a class you want to mark final.
    final!
  end
end
```

### Lazy Accessors

```ruby
class User
  # Enable the feature in a given class via the using directive. Alternatively,
  # you can enable it in a higher-level module, so that all classes defined in
  # support lazy accessors.
  using FeatureEnvy::LazyAccessor

  # These are some attributes that will be used by the lazy accessor.
  attr_accessor :first_name, :last_name

  # full_name is computed in a thread-safe fashion, and is lazy, i.e. it's
  # computed on first access and then cached.
  lazy(:full_name) { "#{first_name}" "#{last_name}" }
end
```

### Object Literals

```ruby
# Object literals are inspired by JavaScript and enable inline object definition
# that mixes both attributes and methods. Consider the example below:
app = object do
  @database = create_database_connection
  @router   = create_router

  def start
    @database.connect
    @router.start
  end
end

# app has @database and @router as attributes and responds to #start.
app.start
```

### Inspect

```ruby
# Elixir-style inspect for debugging during development and testing. First,
# make #inspect! available on all objects.
class BasicObject
  include FeatureEnvy::Inspect
end

# Second, configure how objects are inspected and where the results are sent.
# In this case, we just call the regular #inspect and send results to stderr.
FeatureEnvy::Inspect.inspector = FeatureEnvy::Inspect::InspectInspector
FeatureEnvy::Inspect.output = $stderr

# Alternatively, in a Rails app:
FeatureEnvy::Inspect.output = FeatureEnvy::Inspect::LoggerAdapter.new Rails.logger

# Now, inspect! is ready to use. For example, this will print the user to stderr
# or via the logger, depending on which output above was chosen.
User.find(5).inspect!
```

## Author

This gem is developed and maintained by [Greg Navis](http://www.gregnavis.com).
