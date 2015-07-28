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

var updateGoogleLink = function updateGoogleLink($stack){
  var link = $stack.find('li:first').data('google-link');
  $('.js-google-link').attr('href', link);
}

var updateProgressBar = function updateProgressBar(){
  var total = $('.progress-bar').data('total');
  var remaining = $('.js-extra-cards li, .js-cardswipe li').length;
  var done = total - remaining;
  var percent = (done / total) * 100;
  $('.progress-bar div').animate({
    width: percent + '%'
  });
  if (percent === 100) {
    $('.js-controls').fadeOut(100);
    $('.level-complete').fadeIn(100);
  }
}

var filterElements = function filterElements(){
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
}

function saveResponse(response) {
  if(window.onboarding) {
    if ($('.js-extra-cards li, .js-cardswipe li').length === 0){
      return $.ajax({
        url: '/onboarding-complete',
        method: 'POST'
      });
    }
  } else {
    delete response.googleLink;

    return $.ajax({
      url: '/responses',
      method: 'POST',
      data: {
        response: response
      }
    });
  }
}

$(function(){

  // Animate any messages that have been sent from the server
  if($('.app-messages *').length){
    setTimeout(function(){
      showMessages(3000);
    }, 500);
  }

  if($('.js-cardswipe').length){
    window.onboarding = ( $('.onboarding-page').length > 0 );

    $(".js-cardswipe").cardSwipe({
      choices: {
        male: {
          direction: 'left',
          $button: $('.js-choose-male'),
          overlaySelector: '.js-overlay-male'
        },
        female: {
          direction: 'right',
          $button: $('.js-choose-female'),
          overlaySelector: '.js-overlay-female'
        },
        other: {
          direction: 'down',
          $button: $('.js-choose-other'),
          overlaySelector: '.js-overlay-other'
        },
        skip: {
          direction: 'up',
          $button: $('.js-choose-dontknow'),
          overlaySelector: '.js-overlay-dontknow'
        }
      },
      onChoiceMade: function(choice, $card, $stack){
        response = $card.data();
        response.choice = choice;

        $card.remove();
        saveResponse(response);

        $('.js-extra-cards').children().eq(0).appendTo($stack);

        updateGoogleLink($stack);
        updateProgressBar();
      },
      onKeyboardShortcut: function(direction){
        ga('send', 'event', 'cardSwipe', 'keyboardShortcut', direction);
      },
      onButtonPress: function(direction){
        ga('send', 'event', 'cardSwipe', 'buttonPress', direction);
      },
      onSwipe: function(direction){
        ga('send', 'event', 'cardSwipe', 'swipe', direction);
      }
    });

    $('.controls__google a').on('click', function(){
      ga('send', 'event', 'googleThem', 'click');
    });
  }

  $('[data-filter-elements]').on('keyup', filterElements).one('focus', function(){
    var label = $('label[for="' + $(this).attr('id') + '"]').text();
    ga('send', 'event', 'filterElements', 'focus', label);
  });

});
