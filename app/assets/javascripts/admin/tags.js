$(document).on('turbolinks:load', function() {
  $("#service_keywords,#organization_accreditations,#organization_licenses").select2({
    tags: [''],
    tokenSeparators: [',']
  });
});
