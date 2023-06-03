# Feature Envy

Feature Envy enhances Ruby with features found in other programming languages.

**WARNING**: This gem is still in development and a stable release hasn't been
made yet. Bug reports and contributions are welcome!

## Supported Features

| Name            | Inspiration | Description                                                           |
|-----------------|-------------|-----------------------------------------------------------------------|
| Final Classes   | Java        | Classes that cannot  be inherited.                                    |
| Lazy Accessor   | Swift       | Lazy attributes whose values are computed in a thread-safe way.       |
| Object Literals | JavaScript  | One-off objects with attributes and methods without defining a class. |
| Inspect         | Elixir      | Easily print intermediate objects during debugging and development.   |

## Installation

You can install the gem by running `gem install feature_envy` or adding it to
`Gemfile`:

```ruby
gem "feature_envy"
```

Don't forget to run `bundle install` afterwards.

## Features

Below are example snippets for a quick start with the project. Please refer to
individual feature documentation for details. Features are designed to be
independent and should be enabled one-by-one.

### Final Classes

#### Definition

A final class is a class that cannot be inherited.

#### Motivation

Most classes are not designed with inheritance in mind. Inheriting such class,
and overriding its methods, can result in buggy code. Marking a class final
signals to others its not prepared for being inherited, and prevents subclass
creation.

#### Usage

1. Enable the feature in a given scope via `using FeatureEnvy::FinalClass`.
2. Call `final!` inside a class to be marked final.

#### Example

```ruby
module Models
  # The feature must be enabled explicitly.
  using FeatureEnvy::FinalClass

  class Admin < User
    # Calling final! inside a class body marks it final.
    final!
  end

  # This will result in an exception.
  class SuperAdmin < Admin; end
end
```

### Lazy Accessors

#### Definition

A lazy accessor is an accessor that computes and caches its value the first time
it's called.

#### Motivation

Some attributes are based upon other attributes and are expensive to compute.
Lazy accessors delay their computation until first use, and reuse the same
value on subsequent calls.

#### Usage

1. Enable the feature in a given scope via `using FeatureEnvy::LazyAccessor`.
2. Define lazy accessors using `lazy(:name) { value }`.

#### Example

```ruby
class User
  # The feature must be enabled explicitly.
  using FeatureEnvy::LazyAccessor

  # These are some attributes that will be used by the lazy accessor.
  attr_accessor :first_name, :last_name

  # #full_name is computed on first call and reused on subsequent calls. The
  # computation is thread-safe.
  lazy(:full_name) { "#{first_name}" "#{last_name}" }
end
```

### Object Literals

#### Definition

Object literals are objects (both attributes and methods) spelled out explicitly
in the code, without defining a dedicated class.

#### Motivation

Some classes are defined to be instantiated only once. Sometimes that class
definition can be removed, and object can be instantiated literally in a
"classless" way.

#### Usage

1. Enable the feature in a given scope via `using FeatureEnvy::ObjectLiteral`.
2. Define literal objects by calling `object` and defining its attributes and
   methods inside the block.

#### Example

```ruby
app = object do
  # The attributes set inside the block are set on the object being defined.
  @database = create_database_connection
  @router   = create_router

  # Similarly, the methods are define on that object, too.
  def start
    @database.connect
    @router.start
  end
end

# app has @database and @router as attributes and responds to #start.
app.start
```

### Inspect

#### Definition

A development and debugging helper for printing intermediate objects that
combines `#tap`, `#inspect` and `#puts` in one convenient call.

#### Motivation

Printing intermediate objects can be cumbersome during development and
debugging. Take `User.find(1).confirm_account!` as an example. Printing the user
would require assigning it to a variable or writing `tap { puts inspect }`
before `confirm_account!`.

#### Usage

1. Ensure the code is **NOT** running in production, as this is a development
   tool.
2. Include `FeatureEnvy::Inspect` in `BasicObject`.
3. Set `FeatureEnvy::Inspect.inspector` to `FeatureEnvy::Inspect::InspectInspector`.
4. Set `FeatureEnvy::Inspect.output` to `$stderr` or ...
5. Set `FeatureEnvy::Inspect.output` to `FeatureEnvy::Inspect::LoggerAdapter.new(Rails.logger)`.

#### Example

```ruby
# Check that it's NOT production.
if !Rails.env.production?
  # Include FeatureEnvy::Inspect in BasicObject.
  class BasicObject
    include FeatureEnvy::Inspect
  end

  # Configure how objects are inspected and where the results are sent. Here
  # we're using the built-in #inspect and print to $stderr.
  FeatureEnvy::Inspect.inspector = FeatureEnvy::Inspect::InspectInspector
  FeatureEnvy::Inspect.output = $stderr

  # Alternatively, output can be sent to a logger:
  FeatureEnvy::Inspect.output = FeatureEnvy::Inspect::LoggerAdapter.new Rails.logger
end

# #inspect! is ready to use! The example below will print the user without
# who's having his account confirmed.
User.find(1).inspect!.confirm_account!
```

## Author

This gem is developed and maintained by [Greg Navis](http://www.gregnavis.com).
