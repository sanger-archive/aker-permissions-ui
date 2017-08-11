// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

$(document).ready(function(){
  $("a[data-remote]").on("ajax:success", function (e, data, status, xhr) {
    $("#viewEditStamp").html($("#viewEditStamp", xhr.responseText).html());
    aker.attachSelectize($("#viewEditStamp"));
  }).on("ajax:error", function(e, xhr, status, error) {
    $("#viewEditStamp").append("<p>ERROR</p>");
  });

  $("#viewEditStamp").on('show.bs.modal', function(e) {
    $("#viewEditStamp").html('');
  })

  aker.attachSelectize(document.body);
});

$(document).on("turbolinks:load", function() {
  aker.attachSelectize(document.body);
});

window.aker = {};
window.aker.attachSelectize = function(node) {
  $("[data-behavior~=selectize]", node).each(window.aker.selectize_element);
};
window.aker.selectize_element = function(index, el) {
  $(el).selectize({
    plugins: ['remove_button'],
    delimiter: ',',
    persist: false,
    create: function(input) {
      return {
          value: input,
          text: input
      }
    }
  });
};
