module Commands
  class ChooseDrinkType < Base
    include Import[repo: 'repositories.drink_type_repo']

    def handle_call(message)
      username = username_for(message.from)
      send_message(
        chat_id: message.chat.id,
        text: '📆 Choose a type of drink',
        parse_mode: :markdown,
        reply_markup: menu_keyboard
      )
    end

    def handle_callback(callback, args)
      id = args.fetch('id') { raise(FallbackError) }
      drink = repo.by_id(id) || raise(FallbackError)
      username = username_for(callback.from)
      confirmed = args.fetch('confirm', false)
      volumed = args.fetch('volume_check', false)
      if !confirmed && !volumed
        ask_for_volume(callback, drink)
      elsif !confirmed && volumed
        ask_for_count(callback, drink)
      else
        report_success(callback)
      end
    end

    def ask_for_volume(callback, drink)
      volume_buttons = drink.volumes.map { |volume| button(volume, 'volume', { id: drink.id, volume_check: true }) }
      edit_message_text(
        message_id: callback.message.message_id,
        chat_id: callback.message.chat.id,
        text: "Let choose volume of drink",
        parse_mode: :markdown,
        reply_markup: inline_keyboard(
          volume_buttons,
          [button('Cancel', 'back', replace: true) ]
        )
      )
    end

    def ask_for_count(callback, drink)
      count_buttons = [1,2,3,4].map { |count| button(count, 'count', { id: drink.id, confirm: true }) }
      edit_message_text(
        message_id: callback.message.message_id,
        chat_id: callback.message.chat.id,
        text: "Let choose count of glasses",
        parse_mode: :markdown,
        reply_markup: inline_keyboard(
          count_buttons,
          [button('Cancel', 'back', replace: true) ]
        )
      )
    end

    def report_success(callback)
      delete_message(
        message_id: callback.message.message_id,
        chat_id: callback.message.chat.id
      )

      send_message(
        chat_id: callback.message.chat.id,
        text: "Well done!",
        parse_mode: :markdown,
        reply_markup: Keyboards::MainReplyKeyboard.new.call
      )
    end

    def menu_keyboard
      buttons = repo.all.map { |drink| button_for(drink) }.each_slice(3).to_a
      inline_keyboard(*buttons)
    end

    def button_for(drink)
      button("#{drink.emoji} #{drink.name} #{drink.abv}%", 'drink', { id: drink.id })
    end
  end
end
