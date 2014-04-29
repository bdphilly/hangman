class Game

  attr_accessor :current_status, :guesser, :guessee

  def initialize
    @guesser = ComputerPlayer.new
    @guessee = ComputerPlayer.new
  end

  def win?
    # self.secret_word == self.current_status
    self.current_status.chars.none? { |char| char == '_' }
  end

  def run
    turns_left = 10
    user_guess = ''

    secret_word_length = self.guessee.get_word_length
    self.current_status = '_' * secret_word_length

    # puts self.guessee.secret_word

    puts "Welcome to Hangman! The word is #{secret_word_length} characters long."

    while (turns_left > 0)
      # puts self.secret_word
      puts self.current_status
      puts "#{turns_left} guesses remaining"
      user_guess = self.guesser.get_guess(self.current_status)
      decrement, self.current_status = self.guessee.update_current_status(user_guess, self.current_status)
      turns_left -= decrement
      if self.win?
        puts self.current_status
        puts "YOU WON!"
        return
      end
    end
    puts "You lose."
  end

end

class HumanPlayer

  def initialize
  end

  def get_word_length
    puts "Please have a word in mind. How long is this word?"
    gets.chomp.to_i
  end

  def get_guess(current_status)
    user_guess = nil
    loop do
      puts "What is your guess?"
      user_guess = gets.chomp
      break if valid_guess?(user_guess)
      puts "Incorrect format. Please enter a single letter!"
    end
    user_guess
  end

  def valid_guess?(user_input)
    user_input.length == 1
  end

  def update_current_status(user_guess, current_status)
    decrement = 1
    puts "Is the computer's guess correct? (Y/N)"
    if gets.chomp.downcase == 'n'
      return [decrement, current_status]
    end

    # format: "3,10" XXX - make sure user doesn't overwrite indicies XXX
    puts "Enter the correct indices, separated by commas:"
    correct_indices = gets.chomp.split(',')
    correct_indices.map(&:to_i).each do |correct_index|
      current_status[correct_index] = user_guess
      decrement = 0
    end

    [decrement, current_status]
  end

end

class ComputerPlayer

  attr_accessor :secret_word, :previous_guesses, :dictionary, :has_AI

  def initialize
    @secret_word = File.readlines('dictionary.txt').sample.chomp
    @previous_guesses = []
    @dictionary = set_dictionary
    @has_AI = true
  end

  def set_dictionary
    new_dictionary = []
    File.foreach("dictionary.txt") do |line|
      new_dictionary << line.chomp.downcase
    end
    new_dictionary
  end

  def get_word_length
    self.secret_word.length
  end

  def get_guess(current_status)
    computer_guess = ''

    if self.has_AI
      computer_guess = make_intelligent_guess(current_status)
    else
      loop do
        computer_guess = ('a'..'z').to_a.sample
        break unless self.previous_guesses.include?(computer_guess)
      end
    end
    self.previous_guesses << computer_guess
    puts self.previous_guesses
    puts self.previous_guesses.length

    puts "The computer guesses: #{computer_guess}"
    computer_guess
  end

  def update_current_status(user_guess, current_status)
    turn_decremented = 1
    if self.secret_word.include?(user_guess)
      self.secret_word.chars.each_with_index do |char, index|
        if user_guess == char
          current_status[index] = char
          turn_decremented = 0
        end
      end
    end
    [turn_decremented, current_status]
  end

  def make_intelligent_guess(current_status)

    current_dictionary = initial_update_dictionary(current_status)

    current_dictionary = eliminate_non_matches(current_status, current_dictionary)

    current_dictionary = filter_correct_position(current_status, current_dictionary)

    frequent_letter_in_dictionary(current_status, current_dictionary)
  end

  #tested
  def initial_update_dictionary(current_status)
    self.dictionary.select { |word| word.length == current_status.length }
  end

  #tested
  def eliminate_non_matches(current_status, current_dictionary)
    status_letters = current_status.chars.select { |char| char != "_" }
    letters_not_in_word = self.previous_guesses - status_letters

    cur_dict_dup = current_dictionary.dup

    letters_not_in_word.each do |letter|
      cur_dict_dup.each do |word|
        if word.include?(letter)
          current_dictionary.delete(word)
        end
      end
    end
    current_dictionary
  end

  #tested
  def filter_correct_position(current_status, current_dictionary)

    cur_stat_arr = current_status.split('')

    cur_dict_dup = current_dictionary.dup

    cur_dict_dup.each do |dictionary_word|
      cur_stat_arr.each_with_index do |char, index|
        next if char == '_' || dictionary_word[index] == char
        current_dictionary.delete(dictionary_word)
        break
      end
    end

    current_dictionary
  end

  #tested
  def frequent_letter_in_dictionary(current_status, current_dictionary)

    letter_count = {}
    merged_words = current_dictionary.join('')

    merged_words.each_char do |char|

      if !self.previous_guesses.include?(char)
        if letter_count.has_key?(char)
          letter_count[char] += 1
        else
          letter_count[char] = 1
        end
      end
    end

    common_letter, occurrence = letter_count.max_by { |char, occurrence| occurrence }

    common_letter
  end



end


hangman = Game.new
hangman.run


# dictionary = player1.dictionary[1000..1100]

# player1.previous_guesses = ['a','e','i','o']

# puts player1.filter_correct_position('__a__', dictionary)
# # puts dictionary
# puts player1.filter_correct_position('___l__', dictionary)
# puts
# puts player1.filter_correct_position('a___', dictionary)


