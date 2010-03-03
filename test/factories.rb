Factory.define :region do |f|
  f.name "Wellington Region"
end

Factory.define :district do |f|
  f.name "Wellington City"
  f.association :region
end

Factory.define :category do |c|
  c.sequence(:name) {|n| "Cat#{n}"}
  c.slug "coaches2"
end

Factory.define :subcategory do |sc|
  sc.sequence(:name) {|n| "Subcat#{n}"}
  sc.slug "coaching-life2"
  sc.association :category
end

Factory.define :user_profile do |f|
  f.association :user
end

Factory.define :user do |f|
  f.sequence(:first_name) {|n| "User#{n}"}
  f.last_name "Name"
  f.accept_terms true
  f.association :district
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
end

Factory.define :subcategories_user do |scu|
  scu.association :user
  scu.association :subcategory
end

Factory.define :article do |f|
  f.sequence(:title) {|n| "Article#{n}"}
  f.author {|author| author.association(:user) }
  f.lead "Bla"
  f.body "Bla"
  f.subcategory1_id {|s| s.association(:subcategory) }
end

Factory.define :articles_subcategories do |asu|
  asu.association :article
  asu.association :subcategory
end


Factory.define :order do |f|
  f.association :user
  f.photo true
  f.whole_package false
end

Factory.define :payment do |f|
  f.association :user
  f.association :order
  f.payment_card_type "credit_card"
  f.amount 1500
end

Factory.define :newsletter do |f|
  f.title "May newsletter"
  f.state "published"
  f.publisher {|p| p.association(:user) }
  f.author {|author| author.association(:user) }
  f.main_article "This is the main article"
  f.competition "And our great competition"
  f.bam_news "Here are some news"
  f.upcoming_events "Coming soon"
  f.quotation_quiz "Quiz"
end
