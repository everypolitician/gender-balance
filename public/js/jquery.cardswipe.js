// CardSwipe, a jQuery plugin for performing actions on a stack of cards
// by swiping them in one of four directions, pressing keyboard shortcuts
// and/or pressing buttons.

// Based heavily on jTinder by Dominik Weber (GPL license)
// https://github.com/do-web/jTinder with plugin structure
// from http://jqueryboilerplate.com

// Requires jQuery 1.4.3+ and jquery.transform.js:
// https://github.com/louisremi/jquery.transform.js

;(function($, window, document, undefined){

  // Set up variables common to all instances of the plugin.
  var pluginName = "cardSwipe";
  var defaults = {
    onChoiceMade: function(choice, $card, $button, $stack, animateCurrentCard){
      // Hopefully the user will replace this function
      // with something more useful!
      animateCurrentCard(function(){
        $card.remove();
      });
    },
    $keyListenerContext: $(document),
    keyCodeForDirection: {
      left: 37,
      up: 38,
      right: 39,
      down: 40
    },
    animationRevertSpeed: 200,
    animationSpeed: 400,
    threshold: 1
  };

  function Plugin(domElement, options){
    this.$element = $(domElement);
    this.settings = $.extend({}, defaults, options);
    this._defaults = defaults;
    this._name = pluginName;
    this.init();
  }

  $.extend(Plugin.prototype, {

    init: function(){
      var self = this;

      self.keyListeners = {};
      self.keyCodeForChoice = {};
      self.overlaySelectorAll = [];
      self.movementVars = {
        xStart: 0,
        yStart: 0,
        touchStart: false,
        cardWidth: self.getCurrentCard().width()
      }

      $.each(self.settings.choices, function(choiceName, choiceSettings){

        // Construct a map of keyCode to choiceName, for the
        // keydown listeners to be bound to later on.
        self.keyCodeForChoice[self.settings.keyCodeForDirection[choiceSettings.direction]] = choiceName;

        // Add the overlaySelector to the list
        self.overlaySelectorAll.push(choiceSettings.overlaySelector);

        // Set up a click listener on each choice's button.
        choiceSettings.$button.on('click', function(){
          self.makeChoice(choiceName);

          if('onButtonPress' in self.settings){
            self.settings.onButtonPress(self.settings.choices[choiceName].direction);
          }
        });
      });

      // Set up keydown listener on each choice's associated key.
      this.settings.$keyListenerContext.on('keydown', function(e){
        if(e.keyCode in self.keyCodeForChoice){
          var choiceName = self.keyCodeForChoice[e.keyCode];
          self.makeChoice(choiceName);

          if('onKeyboardShortcut' in self.settings){
            self.settings.onKeyboardShortcut(self.settings.choices[choiceName].direction);
          }
        }
      });

      // Set up swipe/drag handlers on the stack.
      self.$element.on('touchstart mousedown', $.proxy(self.handleMovement, self));
      self.$element.on('touchmove mousemove', $.proxy(self.handleMovement, self));
      self.$element.on('touchend mouseup', $.proxy(self.handleMovement, self));
      self.$element.on('mousedown', function(e){
        self.getCurrentCard().addClass('grabbing');
      });
      self.$element.on('mouseup', function(e){
        self.getCurrentCard().removeClass('grabbing');
      });

      // Flatten the overlaysSelector list into a string for
      // simple use when we want to match any overlay in a card.
      self.overlaySelectorAll = self.overlaySelectorAll.join(', ');

      if('onInit' in self.settings){
        self.settings.onInit(self.$element);
      }
    },

    getCards: function(){
      return this.$element.children();
    },

    getCurrentCard: function(){
      return this.getCards().eq(0);
    },

    getChoiceByDirection: function(direction){
      var self = this;
      var choice;

      $.each(self.settings.choices, function(choiceName, choiceSettings){
        if(choiceSettings.direction === direction){
          choice = choiceName;
          return false; // stop the $.each loop
        }
      });

      return choice;
    },

    makeChoice: function(choiceName){
      // Animates the top card, in the direction specified by the
      // choice settings, and then calls onChoiceMade() callback,
      // to execute the user’s specified clean-up function.

      var self = this;
      var choiceSettings = self.settings.choices[choiceName];
      var $currentCard = self.getCurrentCard();
      var $choiceOverlay = $(choiceSettings.overlaySelector, $currentCard);
      var animationSpeed = self.settings.animationSpeed;

      $(self.overlaySelectorAll, $currentCard).css('opacity', 0);
      $(choiceSettings.overlaySelector, $currentCard).css('opacity', 1);

      if(choiceSettings.direction == 'left'){
        var translate = (self.movementVars.cardWidth * 3 * -1) + 'px,' + (self.movementVars.cardWidth * -1) + 'px';
        var animateToCss = {
          transform: 'translate(' + translate + ') rotate(-60deg)'
        };

      } else if(choiceSettings.direction == 'up'){
        var translate = (self.movementVars.cardWidth * 0.3) + 'px,' + (self.movementVars.cardWidth * 3 * -1) + 'px';
        var animateToCss = {
          transform: 'translate(' + translate + ') rotate(20deg)'
        };

      } else if(choiceSettings.direction == 'right'){
        var translate = (self.movementVars.cardWidth * 3) + 'px,' + (self.movementVars.cardWidth * -1) + 'px';
        var animateToCss = {
          transform: 'translate(' + translate + ') rotate(60deg)'
        };

      } else if(choiceSettings.direction == 'down'){
        var translate = (self.movementVars.cardWidth * 0.6 * -1) + 'px,' + (self.movementVars.cardWidth * 5) + 'px';
        var animateToCss = {
          transform: 'translate(' + translate + ') rotate(-20deg)'
        };

      } else {
        var animateToCss = {
          "transform": "scale(1.2)",
          "opacity": 0
        };
        var animationSpeed = self.settings.animationSpeed / 2;
      }

      // User-specified onChoiceMade functions should call this to
      // animate the current card off the stack. They can supply a
      // callback in onAnimationComplete, to be run after the
      // animation has finished.
      var animateCurrentCard = function(onAnimationComplete){
        $currentCard.addClass('animating').animate(
          animateToCss,
          animationSpeed,
          onAnimationComplete
        );
      }

      self.settings.onChoiceMade(
        choiceName,
        self.getCurrentCard(),
        choiceSettings.$button,
        self.$element,
        animateCurrentCard
      );
    },

    abortChoice: function(){
      var self = this;
      var $currentCard = self.getCurrentCard();

      $currentCard.animate({
        transform: "translate(0px,0px) rotate(0deg)"
      },
      self.settings.animationRevertSpeed);

      $(self.overlaySelectorAll, $currentCard).animate({
        opacity: 0
      },
      self.settings.animationRevertSpeed);
    },

    handleMovement: function(ev){
      ev.preventDefault();
      var self = this;

      var $cards = self.getCards();
      var $currentCard = self.getCurrentCard();

      switch (ev.type) {
        case 'mousedown':
        case 'touchstart':
          if(self.movementVars.touchStart === false) {
            self.movementVars.touchStart = true;
            self.movementVars.xStart = (typeof ev.pageX == 'undefined') ? ev.originalEvent.touches[0].pageX : ev.pageX;
            self.movementVars.yStart = (typeof ev.pageY == 'undefined') ? ev.originalEvent.touches[0].pageY : ev.pageY;
            self.movementVars.cardWidth = $currentCard.width();
          }
        case 'mousemove':
        case 'touchmove':
          if(self.movementVars.touchStart === true) {
            var pageX = (typeof ev.pageX == 'undefined') ? ev.originalEvent.touches[0].pageX : ev.pageX;
            var pageY = (typeof ev.pageY == 'undefined') ? ev.originalEvent.touches[0].pageY : ev.pageY;
            var deltaX = parseInt(pageX) - parseInt(self.movementVars.xStart);
            var deltaY = parseInt(pageY) - parseInt(self.movementVars.yStart);
            var percent = (100 / self.movementVars.cardWidth) * deltaX;

            var translate = deltaX + 'px,' + deltaY + 'px';
            $currentCard.css('transform', 'translate(' + translate + ') rotate(' + (percent / 8) + 'deg)');

            // Adjust opacity of the right direction overlay in the current card.
            if(Math.abs(deltaX) < Math.abs(deltaY)){
              var axis = deltaY;
              if(axis >= 0){
                var direction = 'down';
              } else {
                var direction = 'up';
              }
            } else {
              var axis = deltaX;
              if(axis >= 0){
                var direction = 'right';
              } else {
                var direction = 'left';
              }
            }
            var choiceSettings = self.settings.choices[self.getChoiceByDirection(direction)];
            var opacity = (Math.abs(axis) / self.settings.threshold) / 100 + 0.2;
            $(self.overlaySelectorAll, $currentCard).css('opacity', 0);
            $(choiceSettings.overlaySelector, $currentCard).css('opacity', Math.min(opacity, 1));
          }
          break;
        case 'mouseup':
        case 'touchend':
          self.movementVars.touchStart = false;
          var pageX = (typeof ev.pageX == 'undefined') ? ev.originalEvent.changedTouches[0].pageX : ev.pageX;
          var pageY = (typeof ev.pageY == 'undefined') ? ev.originalEvent.changedTouches[0].pageY : ev.pageY;
          var deltaX = parseInt(pageX) - parseInt(self.movementVars.xStart);
          var deltaY = parseInt(pageY) - parseInt(self.movementVars.yStart);

          // They have finished dragging.
          // Decide what to do with the card.
          if(Math.abs(deltaX) < Math.abs(deltaY)){
            // Vertical swipe.
            var axis = deltaY;
            var positive = 'down';
            var negative = 'up';
          } else {
            // Horizontal swipe.
            var axis = deltaX;
            var positive = 'right';
            var negative = 'left';
          }

          // Only perform an action if they've crossed the certainty threshold.
          var certainty = (Math.abs(axis) / self.settings.threshold) / 100 + 0.2;
          if(certainty >= 1){
            if(axis > 0){
              self.makeChoice(self.getChoiceByDirection(positive));
              if('onSwipe' in self.settings){
                self.settings.onSwipe(positive);
              }
            } else {
              self.makeChoice(self.getChoiceByDirection(negative));
              if('onSwipe' in self.settings){
                self.settings.onSwipe(negative);
              }
            }
          } else {
            self.abortChoice();
          }
          break;
      }
    }
  });

  // Bind cardswipe to an element containing cards,
  // by calling the .cardSwipe() jQuery method.
  $.fn[pluginName] = function(options){
    this.each(function(){

      // Avoid creating cardSwipe instance multiple times on the same element.
      if( ! $.data(this, "plugin_" + pluginName) ){
        $.data(this, "plugin_" + pluginName, new Plugin(this, options));
      }
    });

    // Return the jQuery object for chaining.
    return this;
  };

})(jQuery, window, document);
