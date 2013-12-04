// = require jquery
// = require jquery_ujs
// = require underscore
// = require gmaps/google

$(function() {
    // Submit form when changing a select menu.
    $(document).on('change', 'form[data-submit-onchange] select', function() {
        $(this).parents('form').submit();
    });

    // Submit form when changing text of an input field
    $(document).on('change', 'form[data-submit-onchange] input[type=text]', function() {
        $(this).parents('form').submit();
    });

    // Submit form when clicking on checkbox
    $(document).on('click', 'form[data-submit-onchange] input[type=checkbox]:not(input[data-ignore-onchange])', function() {
        $(this).parents('form').submit();
    });
});
