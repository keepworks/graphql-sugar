# GraphQL::Sugar

A sweet, extended DSL written on top of the [graphql-ruby](https://github.com/rmosolgo/graphql-ruby) gem.

**Looking for a quick overview of this gem in action?** Head over to the [Usage](#usage) section.

This gem allows you to:

* Easily write [object types](#object-types) and [input types](#input-types) that are backed by ActiveRecord models.
  * Automatically convert field names to snake_case.
  * Automatically add `id`, `createdAt` and `updatedAt` fields if these columns exist in your database schema.
  * Automatically determine the type of the field, based on your database schema and model validation rules, keeping things DRY.
* Easily write [resolvers](#resolvers) and [mutators](#mutators) to encapsulate query and mutation logic.
  * Provide an object-oriented layer, allowing easy refactoring of common code across queries and mutations.
  * Look like (and function very similar to) Rails controllers, so that writing them is a breeze.

## Installation

```ruby
gem 'graphql'
gem 'graphql-sugar'
```

And then execute:

    $ bundle

And finally, do some initial setup:

    $ rails g graphql:sugar

## Usage

This section provides a quick overview of the how simple the DSL can be, as well as a general workflow to follow:

### Writing Queries

Create the ObjectType:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attribute :title
  attribute :content
  attribute :isPublic

  relationship :user
  relationship :comments
end
```

Create a [Resolver](#resolvers):

```ruby
class PostResolver < ApplicationResolver
  parameter :id, !types.ID

  type Types::PostType.to_non_null_type // If `type` is not set, it is automatically determined to be `Types::PostType`

  def resolve
    Post.find(params[:id])
  end
end
```

Expose the Resolver:

```ruby
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  resolver :post
end
```

### Writing Mutations

Create the InputObjectType:

```ruby
Inputs::PostInputType = GraphQL::InputObjectType.define do
  name 'PostInput'

  model_class Post

  parameter :title
  parameter :content
end
```

Create a [Mutator](#mutators):

```ruby
class CreatePostMutator < ApplicationMutator
  parameter :input, !Inputs::PostInputType

  type Types::PostType.to_non_null_type

  def mutate
    Post.create!(params[:input])
  end
end
```

Expose the Mutator:

```ruby
Types::MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  mutator :createPost
end
```

## Usage

### Object Types

Start by generating an ObjectType as you normally would:

    $ rails g graphql:object Post

This would create the following under `app/graphql/types/post_type.rb`:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  name "Post"
end
```

Replace the `name` line with a `model_class` declaration:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post
end
```

This automatically sets the name as `PostType`. If you wish to overwrite the name, you can pass a second argument:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post, 'PostObject'
end
```

The `model_class` declaration is **required** to use rest of the extended ObjectType DSL (like `attributes`, `attribute`, `relationships`, `relationship`, etc). If you forget to declare it however, a helpful exception is raised. :smile:

#### Defining attributes

*Normally*, this is how you would add a couple of fields to your ObjectType:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  field :id, !types.ID
  field :title, !types.String
  field :content, types.String
  field :isPublic, !types.Boolean, property: :is_public
  field :createdAt
  field :updatedAt
end
```

However, using GraphQL::Sugar, you can now shorten this to:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attribute :title
  attribute :content
  attribute :isPublic
end
```

Under the hood:

* The `id`, `createdAt` and `updatedAt` fields are automatically added if your model has those attributes.
* The type for the rest of the fields are automatically determined based on your `schema.rb` and model validations. (Read more about [automatic type resolution](#automatic-type-resolution).)
* The fields automatically resolve to the snake_cased method names of the attribute name provided (eg. `isPublic` => `is_public`).

You can shorten this further [active_model_serializers](https://github.com/rails-api/active_model_serializers)-style:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attributes :title, :content, :isPublic
end
```

Or even more simply:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attributes
end
```

... which automatically includes *all* the attributes of a model based on your schema. While NOT recommended for production, this provides easy scaffolding of model-backed object types during development.

Internally `attribute` just defines a `field`, but automatically determines the type and resolves to the model's snake_cased attribute. For simplicity, it follows the *exact same syntax* as `field`, so you can override type or specify a `resolve:` function:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attribute :thumbnail, types.String, resolve: ->(obj, args, ctx) { obj.picture_url(:thumb) }
end
```

This is useful (and necessary) if you wish to expose `attr_accessor`s defined in your model. (Read more about [automatic type resolution](#automatic-type-resolution).)

**Side Note:** You _can_ always mix in good ol' `field`s along with `attribute`s if you really need to access the old DSL:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  attribute :title
  field :isArchived, types.Boolean, resolve: ->(obj, args, ctx) { obj.is_archived? }
end
```

However, since the syntax is pretty much the same, it is preferable to use either `field` or `attribute` throughout the type definition for the sake of uniformity. You may have a non-model backed ObjectType for example, which can use `field`s.

#### Defining relationships

Assume the Post model has the following associations:

```ruby
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments
end
```

*Normally*, this is how you would define the relationship in your ObjectType:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  field :userId, !types.ID, property: :user_id
  field :user, Types::UserType

  field :comments, !types[Types::CommentType]
end
```

However, using GraphQL::Sugar, you can now shorten this to:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  relationship :user
  relationship :comments
end
```

Under the hood:

* If the relationship is **belongs_to**, it automatically defines a field for the corresponding foreign key. It also determines the type and marks the association as non-null using [automatic type resolution](#automatic-type-resolution).
* If the relationship is **has_one** or **has_many**, it first looks for a corresponding [Resolver](#resolvers) (eg. in this case, `CommentsResolver`). If it doesn't find one, it defaults to calling method of the underlying association on the object (eg. `obj.comments`)

You can shorten the above code to:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  relationships :user, :comments
end
```

Or even more simply:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  relationships
end
```

... which automatically reflects on *all* your model associations and includes them. While NOT recommended for production, this provides easy scaffolding of model-backed object types during development.

**Side Note:** Unlike `attribute`, `relationship` is not just syntactic sugar for `field` and it does much more. It is recommended that you revert to using `field`s (rather than `attribute`) if you need to achieve a specific behavior involving associations. For example:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  model_class Post

  relationship :user

  field :recentComments, !types[Types::CommentType], resolve: ->(obj, args, ctx) {
    obj.comments.not_flagged.recent.limit(3)
  }
  end
end
```

#### Automatic Type Resolution

Your model attribute's type is automatically determined using Rails' reflection methods, as follows:

* First, we look at the column type:
  * `:integer` gets mapped to `types.Int` (`GraphQL::INT_TYPE`),
  * `:float` and `:decimal` get mapped to `types.Float` (`GraphQL::FLOAT_TYPE`),
  * `:boolean` gets mapped to `types.Boolean` (`GraphQL::BOOLEAN_TYPE`),
  * and the rest get mapped to `types.String` (`GraphQL::STRING_TYPE`).
* Then, we determine the non-nullability based on whether:
  * You have specified `null: false` for the column in your schema, or
  * You have specified `presence: true` validation for the attribute in your model.

In instances where a type cannot be automatically determined, you must provide the type yourself. For example, `attr_accessor`s are not persisted and don't have a corresponding column in your database schema.

### Input Types

*Normally*, this is how you would define your InputObjectType:

```ruby
Inputs::PostInputType = GraphQL::InputObjectType.define do
  name 'PostInput'

  argument :title, types.String
  argument :content, types.String
  argument :isPublic, types.Boolean, as: :is_public
end
```

However, using GraphQL::Sugar, you can now shorten this to:

```ruby
Inputs::PostInputType = GraphQL::InputObjectType.define do
  name 'PostInput'

  model_class 'Post'

  parameter :title
  parameter :content
  parameter :isPublic
end
```

Under the hood,
* `parameter` uses the same [automatic type resolution](#automatic-type-resolution) as `attribute`, but creates arguments that are not-null by default. The default behavior passes all values to be validated in the model instead, in order to return proper error messages in the response. (**TODO:** Allow this behavior to be configured via an initializer.)
* It allows sets the `:as` value to the snake_cased form of the provided name. (eg. `:isPublic` => `:is_public`). This allows us to easily pass them into ActiveRecord's `create` and `update_attributes` methods.

You can override the type to make a field non-null as follows:

```ruby
Inputs::PostInputType = GraphQL::InputObjectType.define do
  name 'PostInput'

  model_class 'Post'

  parameter :title, !types.String
  parameter :content
end
```

### Resolvers

In its simplest form, a Resolver simply inherits from `ApplicationResolver` and contains a `#resolve` method.

```ruby
class PostsResolver < ApplicationResolver
  def resolve
    Post.all
  end
end
```

To expose the resolver as a field, declare it in your root QueryType:

```ruby
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  resolver :posts
end
```

To declare arguments, you can use the `parameter` keyword which follows the same syntax:

```ruby
class PostResolver < ApplicationResolver
  parameter :id, !types.ID

  def resolve
    Post.find(params[:id])
  end
end
```

The benefit is that all `parameter`s (read: arguments) are loaded into a `params` object, with all keys transformed into snake_case. This allows them to be easily used with ActiveRecord methods like `where` and `find_by`.

You also have `object` and `context` available in your resolve method:

```ruby
class PostsResolver < ApplicationResolver
  def resolve
    (object || context[:current_user]).posts
  end
end
```

#### Thinking in Graphs *using Resolvers*

Assume the following GraphQL query ("fetch 10 posts, along with the authors and 2 of their highest rated posts."):

```
query {
  posts(limit: 10) {
    title
    content

    user {
      name

      posts(limit: 2, sort: "rating_desc") {
        title
        rating
      }
    }
  }
}
```

When executed, we resolve both the first and second `posts` using `PostsResolver`. This means:

1. All the `argument`s (or `parameter`s) available to your top level `posts` are available to all your nested `posts`s through relationships without any extra work.

2. The `object` value passed to your `PostsResolver#resolve` function is *very* important. This would be a good place to perform an authorization check to see if the current user has access to this relationship on the `object`.

**A quick detour:** At the top of your graph, you have your **root_value** ([read more](http://graphql-ruby.org/queries/executing_queries.html#root-value)), which the [graphql-ruby](https://github.com/rmosolgo/graphql-ruby) library allows you to set for your schema. By default, this is `null`. You can either *explicitly* set this root_value, or *implicitly* consider to be the current user (or current organization, or whatever your application deems it to be).

For example,

```ruby
class PostsResolver < ApplicationResolver
  def resolve
    parent_object = (object || context[:current_user])
    authorize! :view_posts, parent_object

    parent_object.posts
  end
end
```

### Mutators

In its simplest form, a Mutator simply inherits from `ApplicationMutator` and contains a `#mutate` method:

```ruby
class CreatePostMutator < ApplicationMutator
  parameter :input, !Inputs::PostInputType

  type !Types::PostType

  def mutate
    Post.create!(params[:input])
  end
end
```

To expose the mutator as a field, declare it in your root MutationType:

```ruby
Types::MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  mutator :createPost
end
```

Just like resolvers, you have access to `object`, `params` and `context`:

```ruby
class UpdatePostMutator < ApplicationMutator
  parameter :id, !types.ID
  parameter :input, !Inputs::PostInputType

  type !Types::PostType

  def mutate
    post = context[:current_user].posts.find(params[:id])
    post.update_attributes!(params[:input])
    post
  end
end
```

### Organizing Your Code

When you install the gem using `rails g graphql:sugar`, it creates the following files:

```
app/graphql/functions/application_function.rb
app/graphql/resolvers/application_resolver.rb
app/graphql/mutators/application_mutator.rb
```

All your resolvers inherit from `ApplicationResolver` and all your mutators inherit from `ApplicationMutator`, both of which in turn inherit from `ApplicationFunction`. You can use these classes to write shared code common to multiple queries, mutations, or both.

#### Applying OO principles

*Pagination and Sorting:* You can easily create methods that enable common features.

```ruby
class ApplicationResolver < ApplicationFunction
  include GraphQL::Sugar::Resolver

  def self.sortable
    parameter :sort, types.String
    parameter :sortDir, types.String
  end
end
```

Use in your other resolvers:

```ruby
class PostsResolver < ApplicationResolver
  sortable

  def resolve
    # ...
  end
end
```

*Shared Code:* You can also easily share common code across a specific set of mutators. For example, your `CreatePostMutator` and `UpdatePostMutator` could inherit from `PostMutator`, which inherits from `ApplicationMutator`.

#### Tips for Large Applications

In a large app, you can quite easily end up with tons of mutations. During setup, GraphQL::Sugar adds a few lines to your eager_load_paths so you can group them in folders, while maintaining mutations at the root level. For example,

```
# Folder Structure
app/graphql/mutators/
- posts
  - create_post_mutator.rb
  - update_post_mutator.rb
- users
  - create_user_mutator.rb
  - update_user_mutator.rb
- application_mutator.rb
```

```ruby
Types::MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  mutator :createPost
  mutator :updatePost

  mutator :createUser
  mutator :updateUser
end
```

### Generators

A few basic generators have been written to quickly create some of the boilerplate code. They may not work perfectly, and the generated code may require further editing.

    $ rails g graphql:resolver BlogPosts

Creates a `BlogPostsResolver` class at `app/graphql/resolvers/blog_posts_resolver.rb`.

    $ rails g graphql:mutator CreateBlogPost

Creates a `CreateBlogPostMutator` class under `app/graphql/mutators/create_blog_post_mutator.rb`.

## Credits

Many thanks to the work done by the authors of the following gems, which this gem uses as a foundation and/or inspiration:

- [graphql-ruby](https://github.com/rmosolgo/graphql-ruby)
- [graphql-activerecord](https://github.com/goco-inc/graphql-activerecord)
- [graphql-rails-resolver](https://github.com/colepatrickturner/graphql-rails-resolver)
- [active_model_serializers](https://github.com/rails-api/active_model_serializers)

---

Maintained and sponsored by [KeepWorks](http://www.keepworks.com).

![KeepWorks](http://www.keepworks.com/assets/logo-800bbf55fabb3427537cf669dc8cd018.png "KeepWorks")

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keepworks/graphql-sugar. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
