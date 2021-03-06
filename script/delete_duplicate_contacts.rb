# To be performed after ResourceContacts have been made based on contacts

# Israel Ojo
Contact.transaction do
  contact_to_keep = Contact.find(762)
  duplicate_to_delete = Contact.find(763)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
    resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Jocelyn Bratton-Payne
Contact.transaction do
  contact_to_keep = Contact.find(758)
  to_delete = [Contact.find(872), Contact.find(871)]

  contact_to_keep.title = 'Director of SUD Programs'
  contact_to_keep.save(validate: false)

  to_delete.map do |duplicate|
    duplicate.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
    end
    duplicate.destroy!
  end
end

# Kelsey Barlow
Contact.transaction do
  contact_to_keep = Contact.find(878)
  duplicate_to_delete = Contact.find(218)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Lillian Donnard
Contact.transaction do
  contact_to_keep = Contact.find(254)
  duplicate_to_delete = Contact.find(772)

  contact_to_keep.email = 'Ldonard@GlenwoodLife.org'
  contact_to_keep.save(validate: false)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Meghan Westwood
Contact.transaction do
  contact_to_keep = Contact.find(801)
  duplicate_to_delete = Contact.find(802)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Richard Doran
Contact.transaction do
  contact_to_keep = Contact.find(730)
  duplicate_to_delete = Contact.find(657)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Ronald Peterson
Contact.transaction do
  contact_to_keep = Contact.find(416)
  duplicate_to_delete = Contact.find(107)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end

# Yevola S. Peters
Contact.transaction do
  contact_to_keep = Contact.find(272)
  duplicate_to_delete = Contact.find(710)

  duplicate_to_delete.resource_contacts.each do |resource_contact|
      resource_contact.update!(contact: contact_to_keep)
  end

  duplicate_to_delete.destroy!
end