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

function saveResponse(response) {
  return $.ajax({
    url: '/responses',
    method: 'POST',
    data: {
      response: response
    },
    error: function(xhr) {
      alert("error: " + xhr.responseText);
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
      },
      onLike: function (item) {
        var response = item.data();
        response.choice = 'female';
        saveResponse(response);
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
    });

    $('.js-person-skip').on('click', function(e){
      e.preventDefault();
      var item = $('.js-jtinder').data('plugin_jTinder').getCurrentPane();
      var response = item.data();
      response.choice = 'skip';
      saveResponse(response);
      $('.js-jtinder').jTinder('next');
    });
  }

});
