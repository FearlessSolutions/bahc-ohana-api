# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :category do
    name { 'Food' }
    taxonomy_id { '101' }
    type { 'service' }
    trait :situation do
      type { 'situation' }
    end
  end

  factory :health, class: Category do
    name { 'Health' }
    taxonomy_id { '102' }
    type { 'service' }
  end

  factory :jobs, class: Category do
    name { 'Jobs' }
    taxonomy_id { '105' }
    type { 'service' }
  end

  factory :money, class: Category do
    name { 'Money' }
    taxonomy_id { '106' }
    type { 'service' }
  end

  factory :financial_aid, class: Category do
    name { 'Financial Aid And Loans' }
    taxonomy_id { '107' }
    ancestry { '106' }
    type { 'service' }
  end
end
