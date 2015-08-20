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

var undo = function undo(cardSwipe, $stack){
  var $latestCard = $('.js-done-stack').children().eq(0);
  if ($latestCard.length === 0) return;
  // move newly added card(s) back onto extra cards pile
  $extraCards = $('.js-extra-cards');
  while ($stack.children().length > 1) {
    $stack.children().eq(-1).remove().prependTo($extraCards);
  }
  // move latest swiped card back onto stack
  $latestCard.remove().prependTo($stack).animate({
    transform: "translate(0px,0px) rotate(0deg)"
  },
  cardSwipe.animationRevertSpeed);
  $('span', $latestCard).animate({
    opacity: 0
  },
  cardSwipe.animationRevertSpeed,
  function() {
    updateGoogleLink($stack);
    updateProgressBar();
  });
}

var undoInit = function undoInit(cardSwipe, $stack){
  $(document).on('keydown', function(e) {
    if (e.metaKey && e.keyCode == 90) {
      undo(cardSwipe, $stack);
    }
  });

  $('.js-undo').on('click', function(ev){
    undo(cardSwipe, $stack);
  });
}

var levelComplete = function onLevelComplete(){
  $('.controls').fadeOut(200);
  $('.level-complete').fadeIn(200);
  setTimeout(trophyFlash, 200);
}

var trophyFlash = function trophyFlash(){
  $('.trophy__flash').show().animate({
    transform: 'scale(6)',
    opacity: 0
  }, 200, function(){
    $(this).css({
      display: '',
      transform: '',
      opacity: ''
    })
  });
}

var updateProgressBar = function updateProgressBar(){
  var total = $('.progress-bar').data('total');

  // Cards in the DOM, minus any that are being animated (ie: removed)
  var remaining = $('.js-extra-cards li, .js-cardswipe li').not('.animating').length;

  var done = total - remaining;
  var percent = (done / total) * 100;

  $('.progress-bar div').animate({
    width: percent + '%'
  });

  if (percent === 100) {
    levelComplete();
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

var saveResponse = function saveResponse(response) {
  delete response.googleLink;

  return $.ajax({
    url: '/responses',
    method: 'POST',
    data: {
      response: response
    }
  });
}

var displayClickAnimation = function displayClickAnimation($button){
  $('.js-click-animation', $button).show().animate({
    transform: 'scale(3)',
    opacity: 0
  }, 200, function(){
    $(this).css({
      display: '',
      transform: '',
      opacity: ''
    });
  })
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
      onChoiceMade: function(choice, $card, $button, $stack, animateCurrentCard){
        // Give the user feedback that a choice has been made
        displayClickAnimation($button);

        if(window.onboarding == false) {
          // Save the user's choice
          response = $card.data();
          response.choice = choice;
          saveResponse(response);
        }

        // While response is being saved, animate and then move the top card
        // to the top of the done stack...
        animateCurrentCard(function(){
          var $doneStack = $('.js-done-stack');
          $card.removeClass('animating').remove().prependTo($doneStack);

          // ...And update the various bits of UI relating to the current card
          updateGoogleLink($stack);
          updateProgressBar();
        });

        // ...Append a new card to the bottom of the stack...
        var $newCard = $('.js-extra-cards').children().eq(0);
        var $newCardImage = $newCard.find('.js-person__picture');
        $newCardImage.attr('src', $newCardImage.data('src'));
        $newCard.appendTo($stack);

      },
      onKeyboardShortcut: function(direction){
        ga('send', 'event', 'cardSwipe', 'keyboardShortcut', direction);
      },
      onButtonPress: function(direction){
        ga('send', 'event', 'cardSwipe', 'buttonPress', direction);
      },
      onSwipe: function(direction){
        ga('send', 'event', 'cardSwipe', 'swipe', direction);
      },
      onInit: function($stack){
        updateGoogleLink($stack);
        undoInit(this, $stack);
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
