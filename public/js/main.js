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

var updateGoogleLink = function updateGoogleLink(){
  var link = $('.js-jtinder li').eq(0).attr('data-google-link');
  $('.js-google-link').attr('href', link);
}

function loadNewPerson() {
  $('.js-extra-people li:first-child').appendTo('.js-jtinder ul');

  setTimeout(updateGoogleLink, 500);

  setTimeout(function() {
    var total = $('.progress-bar').data('total');
    var remaining = $('.js-extra-people li, .js-jtinder li').length;
    var done = total - remaining;
    var percent = (done / total) * 100;
    $('.progress-bar div').animate({
      width: percent + '%'
    });
  }, 500);
}

function saveResponse(response) {
  if(window.onboarding){
    return;
  }

  delete response.googleLink;

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

    window.onboarding = ( $('.onboarding-page').length > 0 );

    updateGoogleLink();

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
      threshold: 1,
      likeSelector: '.js-jtinder-liked',
      dislikeSelector: '.js-jtinder-disliked'
    }).on('mousedown', '.tindr-card', function(e){
      $(this).addClass('grabbing');
    }).on('mouseup', '.tindr-card', function(e){
      $(this).removeClass('grabbing');
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
      loadNewPerson();
      $('.js-jtinder').jTinder('next');
      loadNewPerson();
    });

    $('.js-person-skip').on('click', function(e){
      e.preventDefault();
      var item = $('.js-jtinder').data('plugin_jTinder').getCurrentPane();
      var response = item.data();
      response.choice = 'skip';
      saveResponse(response);
      loadNewPerson();
      $('.js-jtinder').jTinder('skip');
    });

    $(document).on('keydown', function(e){
      if(e.keyCode == 77 || e.keyCode == 37){
        // m key or left arrow
        $('.js-jtinder-dislike').trigger('click');
      } else if(e.keyCode == 70 || e.keyCode == 39){
        // f key or right arrow
        $('.js-jtinder-like').trigger('click');
      } else if(e.keyCode == 32 || e.keyCode == 38){
        // space key or up arrow
        $('.js-person-skip').trigger('click');
      } else if(e.keyCode == 79 || e.keyCode == 40){
        // o key or down arrow
        $('.js-person-other').trigger('click');
      }
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
