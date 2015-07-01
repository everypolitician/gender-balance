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
          console.log('disliked', item);
      },
      onLike: function (item) {
          console.log('liked', item);
      },
      animationRevertSpeed: 200,
      animationSpeed: 400,
      threshold: 1,
      likeSelector: '.js-jtinder-liked',
      dislikeSelector: '.js-jtinder-disliked'
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
      $('.js-jtinder').jTinder('next');
    });

    $('.js-person-skip').on('click', function(e){
      e.preventDefault();
      $('.js-jtinder').jTinder('next');
    });
  }

});
