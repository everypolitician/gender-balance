var showMessages = function showMessages(hideAfterMilliseconds){
  $('.app-messages').addClass('slide-in');
  if(typeof hideAfterMilliseconds !== 'undefined') {
    setTimeout(hideMessages, hideAfterMilliseconds);
  }
}

var hideMessages = function hideMessages(){
  $('.app-messages').removeClass('slide-in');
  setTimeout(function(){
    $('.app-messages').empty();
  }, 1000);
}

function loadNewPerson() {
  $('.js-extra-people li:last').prependTo('.js-jtinder ul');
  var total = $('.progress-bar').data('total');
  var remaining = $('.js-extra-people li, .js-jtinder li').length;
  var done = total - remaining;
  var percent = (done / total) * 100;
  $('.progress-bar div').animate({
    width: percent + '%'
  });
}

function saveResponse(response) {
  return $.ajax({
    url: '/responses',
    method: 'POST',
    data: {
      response: response
    }
  });
}

$(function(){

  // Animate any messages that have been sent from the server
  if($('.app-messages *').length){
    setTimeout(function(){
      showMessages(3000);
    }, 500);
  }

  if($('.js-jtinder').length){

    $(".js-jtinder").jTinder({
      onDislike: function (item) {
        var response = item.data();
        response.choice = 'male';
        saveResponse(response);
        loadNewPerson();
      },
      onLike: function (item) {
        var response = item.data();
        response.choice = 'female';
        saveResponse(response);
        loadNewPerson();
      },
      animationRevertSpeed: 200,
      animationSpeed: 400,
      threshold: 1
    });

    $('.js-jtinder-like').on('click', function(e){
      e.preventDefault();
      $('.js-jtinder').jTinder('like');
    });

    $('.js-jtinder-dislike').on('click', function(e){
      e.preventDefault();
      $('.js-jtinder').jTinder('dislike');
    });

    $('.js-person-other').on('click', function(e){
      e.preventDefault();
      var item = $('.js-jtinder').data('plugin_jTinder').getCurrentPane();
      var response = item.data();
      response.choice = 'other';
      saveResponse(response);
      $('.js-jtinder').jTinder('next');
      loadNewPerson();
    });

    $('.js-person-skip').on('click', function(e){
      e.preventDefault();
      var item = $('.js-jtinder').data('plugin_jTinder').getCurrentPane();
      var response = item.data();
      response.choice = 'skip';
      saveResponse(response);
      $('.js-jtinder').jTinder('next');
      loadNewPerson();
    });
  }

  $('[data-filter-elements]').on('keyup', function(){
    var $elements = $($(this).attr('data-filter-elements'));
    var searchText = $.trim($(this).val().toLowerCase());

    if(searchText == ''){
      $elements.show();
      return true;
    }

    $elements.each(function(){
      var itemText = $(this).text().toLowerCase();
      var found = itemText.indexOf(searchText) > -1;
      if(found){
        $(this).show();
      } else {
        $(this).hide();
      }
    });
  });

});
