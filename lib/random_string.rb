module RandomString
  def random_string(len=10)
    str, chars = "", ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    str
  end

  def random_word_pair
    pair = []
    pair << RandomWord.adjs.next   #=> "pugnacious"
    pair << RandomWord.nouns.next  #=> "puddle"
    pair.join(' ')
  end

  def random_word(type=:nouns)
    RandomWord.try(type).try(:next)
  end
end
