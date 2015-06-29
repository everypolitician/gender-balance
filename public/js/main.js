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

var loadNewPerson = function loadNewPerson(){
  var people = [
    ['Alex Chalk', 'Conservative Party'],
    ['Alok Sharma', 'Conservative Party'],
    ['Eilidh Whiteford', 'Scottish National Party'],
    ['Angela Smith', 'Labour Party'],
    ['Imran Hussain', 'Labour Party'],
    ['Kit Malthouse', 'Conservative Party'],
    ['Naseem Shah', 'Labour Party'],
    ['Francie Molloy', 'Sinn Féin'],
    ['Glyn Davies', 'Conservative Party'],
    ['Guto Bebb', 'Conservative Party'],
    ['Jo Cox', 'Labour Party'],
    ['Pat Glass', 'Labour Party'],
    ['Ranil Jayawardena', 'Conservative Party'],
    ['Rupa Huq', 'Labour Party']
  ];
  var num = Math.floor(Math.random() * people.length);
  $('.js-jtinder ul').prepend('<li class="person"> \
      <img src="http://api.adorable.io/avatars/200/' + num + '" class="person__picture"> \
      <h1 class="person__name">' + people[num][0] + '</h1> \
      <p class="person__party">' + people[num][1] + '</p> \
      <span class="person__decision person__decision--male js-jtinder-disliked"></span> \
      <span class="person__decision person__decision--female js-jtinder-liked"></span> \
    </li>');
}

$(function(){

  // Animate any messages that have been sent from the server
  if($('.app-messages *').length){
    setTimeout(function(){
      showMessages(3000);
    }, 500);
  }

  if($('.js-jtinder').length){

    // Load two people to begin with
    // (These would probably be hard-coded into the page,
    // but we'll use javascript for now)
    loadNewPerson();
    loadNewPerson();

    $(".js-jtinder").jTinder({
      onDislike: function (item) {
          console.log('disliked', item);
          loadNewPerson();
      },
      onLike: function (item) {
          console.log('liked', item);
          loadNewPerson();
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

  }

});