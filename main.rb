#!/usr/bin/ruby
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0

require 'ruby2d'
require 'securerandom'
STDOUT.sync = true

module Ruby2D
	def get_colour() [self.r, self.g, self.b, self.opacity] end
	def new_colour=(value)
		alpha, self.color = self.opacity, value
		self.opacity = alpha
	end
end

def main
	$width, $height, $fps = 640, 480, 30
	set title: "Colour Match", width: $width, height: $height, fps_cap: $fps
	bg = Image.new 'images/aaron-burden-178369-unsplash.jpg', width: $width, height: $height

	total_time = 45
	particles, speed = [], []
	50.times do
		size = rand(10.0..20.0)
		temp = Circle.new width: size, radius: size, color: "##{SecureRandom.hex(3)}"
		temp.x, temp.y, temp.opacity = rand(size..$width - size), rand(size..$height - size), rand(0.3..0.8)
		particles << temp
		speed << rand(1.0..3.0)
	end

	card1_touched = false
	card1 = Image.new 'images/card.png'
	card1.x, card1.y = $width/2 - card1.width/2, $height/2 - card1.height * 1.5

	card2_touched = false
	card2 = Image.new 'images/card.png'
	card2.x, card2.y = $width/2 - card2.width/2, card1.y + card1.height + 10

	$control = ->(object, operation='r', value=0.05, min_threshold=0.6, max_threshold=1) {
		if operation.start_with?('r') then object.opacity -= value if object.opacity > min_threshold
			else object.opacity += value if object.opacity < max_threshold end
	}

	pause_var, countdown, score, streak = 0, 0, 0, 0
	score_touched = false
	scorebox = Rectangle.new y: 1
	scorelabel = Text.new "SCORE\t#{}", font: 'fonts/Aller_Lt.ttf', color: 'blue', size: 18

	pause_touched = false
	pause = Image.new 'images/pause.png', x: 1, y: 1, z: 3
	pausebox = Rectangle.new x: 1, y: 1, width: pause.width - 1, height: pause.height, z: 2
	pauselabel = Text.new 'Pause', font: 'fonts/Aller_Lt.ttf', x: pausebox.x + pausebox.width, z: 2
	pauselabel.opacity = 0

	time_touched = false
	timebox = Rectangle.new y: 1
	timelabel = Text.new "TIME\t#{}", font: 'fonts/Aller_Lt.ttf', color: 'blue', size: scorelabel.size

	yes_touched, yes_pressed = false, false
	yes = Rectangle.new width: $width/2 - 5, height: 75
	yes.x, yes.y = 1, $height - yes.height - 1

	yes_label = Text.new 'YES', font: 'fonts/Aller_Lt.ttf', size: yes.height/1.5, color: 'lime'
	yes_label.x, yes_label.y = yes.x + yes.width/2 - yes_label.width/2, yes.y + yes.height/2 - yes_label.height/2

	no_touched, no_pressed = false, false
	no = Rectangle.new width: yes.width, height: yes.height
	no.x, no.y = yes.x + yes.width + 8, yes.y

	no_label = Text.new 'NO', font: 'fonts/Aller_Lt.ttf', size: no.height/1.5, color: 'lime'
	no_label.x, no_label.y = no.x + no.width/2 -no_label.width/2, no.y + no.height/2 - no_label.height/2

	card1_label = Text.new %w(red blue yellow black).sample, font: 'fonts/Ubuntu-Regular.ttf', size: 60, color: 'black'
	card1_label.opacity = 0
	card1_label.x, card1_label.y = card1.x + card1.width/2 - card1_label.width/2, card1.y + card1.height/2 - card1_label.height/2

	card2_label = Text.new %w(red blue yellow black).sample, font: 'fonts/Ubuntu-Regular.ttf', size: 60, color: %w(red blue yellow black).sample
	card2_label.opacity = 0
	card2_label.x, card2_label.y = card2.x + card2.width/2 - card2_label.width/2, card2.y + card2.height/2 - card2_label.height/2

	i, elapsed_time = 0, 0

	pause_screen = Rectangle.new width: $width, height: $height, color: 'black', z: 1
	pause_screen.opacity = 0
	started = false

	timer = Text.new '', font: 'fonts/Aller_Lt.ttf', size: 30, z: 3
	scored_message = Text.new '', font: 'fonts/Aller_Lt.ttf', size: 45, z: 3

	play_button_touched = false
	play_button = Image.new 'images/play_button.png', z: 1
	play_button.x, play_button.y = $width/2 - play_button.width/2, $height/2 - play_button.height

	play_label_touched = false
	play_label = Text.new 'Play', font: 'fonts/Aller_Lt.ttf', size: $width/8, z: 1
	play_label.x, play_label.y = $width/2 - play_label.width/2, play_button.y + play_button.height

	play_button2_touched = false
	play_button2 = Image.new 'images/play_button_64x64.png', z: 1, x: pause.x + pause.width, y: pause.y + pause.height

	reset_button_touched = false
	reset_button = Image.new 'images/restart.png', z: 1, y: play_button2.y
	reset_button.x = $width - reset_button.width - pausebox.x - pausebox.width

	exit_touched = false
	exit_button = Image.new 'images/power.png', z: 1
	exit_button.x, exit_button.y = play_button2.x, yes.y - exit_button.height

	stats_touched = false
	stats = Image.new 'images/bulb.png', z: 1
	stats.x, stats.y = reset_button.x, exit_button.y

	card_flux = 0

	beep = Sound.new 'sounds/beep.wav'
	start_sound = Sound.new 'sounds/start_game.ogg'
	correct_sound = Sound.new 'sounds/131662__bertrof__game-sound-correct-v2.wav'
	wrong_sound = Sound.new 'sounds/131657__bertrof__game-sound-wrong.wav'
	timeout = Music.new 'sounds/timeout.wav'
	chime = Sound.new 'sounds/chime.aiff'

	correct = Image.new 'images/correct.png', width: 50, height: 50
	correct.x, correct.y, correct.opacity = card2.x + card2.width/2 - correct.width/2, card1.y + card1.height - correct.height/2, 0

	wrong = Image.new 'images/wrong.png', width: 50, height: 50
	wrong.x, wrong.y, wrong.opacity = card1.x + card1.width/2 - wrong.width/2, card1.y + card1.height - wrong.height/2, 0

	card1_message_touched = false
	card1_message = Image.new 'images/card2_message.png', rotate: 180
	card1_message.x, card1_message.y = card1.x + card1.width/2 - card1_message.width/2, card1.y - card1_message.height
	card1_message_label = Text.new 'meaning', font: 'fonts/ArimaMadurai-Bold.ttf', color: 'green', size: 16
	card1_message_label.x = card1_message.x + card1_message.width/2 - card1_message_label.width/2
	card1_message_label.y = card1_message.y + card1_message.height/2 - card1_message_label.height/1.5

	card2_message_touched = false
	card2_message = Image.new 'images/card2_message.png'
	card2_message.x, card2_message.y = card2.x + card2.width/2 - card2_message.width/2, card2.y + card2.height
	card2_message_label = Text.new 'colour', font: 'fonts/ArimaMadurai-Bold.ttf', color: 'green', size: 16
	card2_message_label.x = card2_message.x + card2_message.width/2 - card2_message_label.width/2
	card2_message_label.y = card2_message.y + card2_message.height/2 - card2_message_label.height/3

	on :key_held do |k|
		yes_touched = true if %w(left a 1 j).include?(k.key)
		no_touched = true if %w(right d 3 ;).include?(k.key)
	end

	on :key_down do |k|
		yes_pressed = true if %w(left a 1 j).include?(k.key)
		no_pressed = true if %w(right d 3 ;).include?(k.key)
		pause_var += 1 if %w(p q space return escape).include?(k.key)
		if !started && k.key == 'escape' then exit elsif k.key == 'escape' then pause_var = 0 end
	end

	on :key_up do |k|
		yes_touched = false if yes_touched == true
		no_touched = false if no_touched == true
	end

	on :mouse_move do |e|
		pause_touched = pausebox.contains?(e.x, e.y) ? true : false
		play_button_touched = play_button.contains?(e.x, e.y) ? true : false
		play_button2_touched = play_button2.contains?(e.x, e.y) ? true : false
		play_label_touched = play_label.contains?(e.x, e.y) ? true : false

		reset_button_touched = reset_button.contains?(e.x, e.y) ? true : false
		exit_touched = exit_button.contains?(e.x, e.y) ? true : false
		stats_touched = stats.contains?(e.x, e.y) ? true : false

		time_touched = timebox.contains?(e.x, e.y) ? true : false
		score_touched = scorebox.contains?(e.x, e.y) ? true : false

		yes_touched = yes.contains?(e.x, e.y) ? true : false
		no_touched = no.contains?(e.x, e.y) ? true : false

		card1_touched = card1.contains?(e.x, e.y) ? true : false
		card2_touched = card2.contains?(e.x, e.y) ? true : false

		card1_message_touched = card1_message.contains?(e.x, e.y) ? true : false
		card2_message_touched = card2_message.contains?(e.x, e.y) ? true : false
	end

	on :mouse_down do |e|
		yes_pressed = yes.contains?(e.x, e.y) ? true : false
		no_pressed = no.contains?(e.x, e.y) ? true : false
	end

	on :mouse_up do |e|
		pause_var += 1 if pausebox.contains?(e.x, e.y) ||\
						(pauselabel.contains?(e.x, e.y) && pauselabel.opacity > 0.2) ||\
						(play_label.contains?(e.x, e.y) && play_label.opacity > 0.2) ||\
						(play_button.contains?(e.x, e.y) && play_button.opacity > 0.2) ||\
						(play_button2.contains?(e.x, e.y) && play_button2.opacity > 0.2)

		if reset_button.contains?(e.x, e.y) and reset_button.opacity > 0.2
			i, score, streak = 0, 0, 0
			pause_var += 1
		end

		exit if exit_button.contains?(e.x, e.y) and exit_button.opacity > 0.2
		Thread.new { system('ruby', 'stats.rb') } if stats.contains?(e.x, e.y) and stats.opacity > 0.2
	end

	available_colours = %w(red blue yellow black)
	colour1 = available_colours
	colour2 = [colour1, available_colours.sample].sample

	update do
		if pause_var % 2 != 0
			$control.call(timer, '')
			timer.x, timer.y = $width/2 - timer.width/2, scored_message.y + scored_message.height
			beep.play if countdown % $fps == 0 and !started

			case (countdown/$fps).to_i
				when 0 then timer.text = 3
				when 1 then timer.text = 2
				when 2 then timer.text = 1
			else
				timer.opacity = 0
				start_sound.play if !started
				started = true
			end
			countdown += 1
		else
			started = false
			countdown = 0
		end

		pause_touched ? $control.call(pausebox) : $control.call(pausebox, '')
		pause.color = pause_touched ? 'lime' : 'white'

		if pause_touched
			$control.call(pauselabel, '', 0.1)
			pausebox.width += 10 if pausebox.width < pauselabel.x + pauselabel.width
		else
			$control.call(pauselabel, 'r', 0.2, 0)
			pausebox.width -= 10 if pausebox.width > pause.x + pause.width
		end

		$control.call(card1_label, '', 0.1)
		$control.call(card2_label, '', 0.1)

		card1_message_label.color = card1_label.get_colour
		card2_message_label.color = card2_label.get_colour

		if started
			$control.call(pause_screen, 'r', 0.05, 0)
			$control.call(play_button, 'r', 0.1, 0)
			$control.call(play_label, 'r', 0.1, 0)
			$control.call(play_button2, 'r', 0.1, 0)
			$control.call(reset_button, 'r', 0.1, 0)
			$control.call(exit_button, 'r', 0.1, 0)
			$control.call(stats, 'r', 0.1, 0)
			$control.call(scored_message, 'r', 0.1, 0)

			$control.call(correct, 'r', 0.1, 0)
			$control.call(wrong, 'r', 0.1, 0)

			i += 1

			if card1_message.y <= card1.y - card1_message.height - 12 then card_flux = 2
				elsif card1_message.y >= card1.y - card1_message.height then card_flux = -1 end

			card1_message.y += card_flux
			card2_message.y += -card_flux

			card1_message_label.y = card1_message.y + card1_message.height/2 - card1_message_label.height/1.5
			card2_message_label.y = card2_message.y + card2_message.height/2 - card2_message_label.height/3

			if total_time - elapsed_time <= 0
				File.open('data/data', 'a+') { |file| file.puts score }
				pause_var, i, score, streak = pause_var + 1, 0, 0, 0
				chime.play

				scored_message.opacity = 1
				scored_message.text = "You Scored: #{File.readlines('data/data')[-1]}"
				scored_message.x = $width/2 - scored_message.width/2
			end

			elapsed_time = (i/$fps).round

			 timeout.play if (total_time - elapsed_time < 10) && (i % $fps == 0)

			if yes_pressed
				card1_colour = Color.new(card1_label.text)
				yes_pressed = false
				if (card2_label.color.r ==  card1_colour.r and\
						card2_label.color.g == card1_colour.g and\
						card2_label.color.b == card1_colour.b)
					score += 1 + streak * 3
					streak += 1
					correct.opacity = 1
					correct_sound.play
				else
					streak = 0
					wrong.opacity = 1
					wrong_sound.play
				end

				colour1 = available_colours.sample
				colour2 = [colour1, [available_colours.sample] * 2].flatten.sample

				card1_label.text, card1_label.color = colour1, 'black'
				card1_label.opacity = 0
				card1_label.x, card1_label.y = card1.x + card1.width/2 - card1_label.width/2, card1.y + card1.height/2 - card1_label.height/2

				card2_label.text, card2_label.color = available_colours.sample, colour2
				card2_label.opacity = 0
				card2_label.x, card2_label.y = card2.x + card2.width/2 - card2_label.width/2, card2.y + card2.height/2 - card2_label.height/2
			end

			if no_pressed
				card1_colour = Color.new(card1_label.text)

				no_pressed = false
				unless (card2_label.color.r ==  card1_colour.r &&\
	 					card2_label.color.g == card1_colour.g &&\
						card2_label.color.b == card1_colour.b)
					score += 1 + streak * 3
					streak += 1
					correct.opacity = 1
					correct_sound.play
				else
					streak = 0
					wrong.opacity = 1
					wrong_sound.play
				end

				colour1 = available_colours.sample
				colour2 = [colour1, [available_colours.sample] * 2].flatten.sample

				card1_label.text, card1_label.color = colour1, 'black'
				card1_label.opacity = 0
				card1_label.x, card1_label.y = card1.x + card1.width/2 - card1_label.width/2, card1.y + card1.height/2 - card1_label.height/2

				card2_label.text, card2_label.color = available_colours.sample, colour2
				card2_label.opacity = 0
				card2_label.x, card2_label.y = card2.x + card2.width/2 - card2_label.width/2, card2.y + card2.height/2 - card2_label.height/2
			end

			if yes_touched
				$control.call(yes, 'r', 0.1)
				yes_label.g -= 0.1 if yes_label.g > 0.3
				yes_label.r += 0.2 if yes_label.r < 1
			else
				$control.call(yes, '')
				yes_label.g += 0.1 if yes_label.g < 1
				yes_label.r -= 0.2 if yes_label.r > 0.5
			end

			if no_touched
				$control.call(no, 'r', 0.1)
				no_label.g -= 0.1 if no_label.g > 0.3
				no_label.r += 0.2 if no_label.r < 1
			else
				$control.call(no, '')
				no_label.g += 0.1 if no_label.g < 1
				no_label.r -= 0.2 if no_label.r > 0.5
			end

			time_touched ? $control.call(timebox) : $control.call(timebox, '')
			score_touched ? $control.call(scorebox) : $control.call(scorebox, '')

			card1_touched ? $control.call(card1) : $control.call(card1, '')
			card2_touched ? $control.call(card2) : $control.call(card2, '')

			card1_message_touched ? $control.call(card1_message) : $control.call(card1_message, '')
			card2_message_touched ? $control.call(card2_message) : $control.call(card2_message, '')
		else
			$control.call(pause_screen, '', 0.05, 1, 0.5)
			$control.call(play_button, '')
			$control.call(play_button2, '')
			$control.call(reset_button, '')
			$control.call(exit_button, '')
			$control.call(stats, '')

			play_label_touched ? $control.call(play_label) : $control.call(play_label, '')

			if play_button_touched then play_button.b -= 0.1 if play_button.b > 0
				else play_button.b += 0.1 if play_button.b < 1
			end

			if play_button2_touched then play_button2.g -= 0.1 if play_button2.g > 0
				else play_button2.g += 0.1 if play_button2.g < 1 end

			if reset_button_touched then reset_button.g -= 0.1 if reset_button.g > 0
				else reset_button.g += 0.1 if reset_button.g < 1 end

			if exit_touched then exit_button.g -= 0.1 if exit_button.g > 0
				else exit_button.g += 0.1 if exit_button.g < 1 end

			if stats_touched then stats.g -= 0.1 if stats.g > 0
				else stats.g += 0.1 if stats.g < 1 end
		end

		timelabel.text = "\tTIME\t\t#{total_time.-(elapsed_time)}\t"
		timebox.x = scorebox.x - timebox.width - 5
		timebox.width, timebox.height = timelabel.width, timelabel.height
		timelabel.x, timelabel.y = timebox.x + timebox.width/2 - timelabel.width/2, timebox.y + timebox.height/2 - timelabel.height/2

		scorelabel.text = "\tSCORE\t\t#{score}\t"
		scorebox.x = $width - scorebox.width - 1
		scorebox.width, scorebox.height = scorelabel.width, scorelabel.height
		scorelabel.x, scorelabel.y = scorebox.x + scorebox.width/2 - scorelabel.width/2, scorebox.y + scorebox.height/2 - scorelabel.height/2

		particles.each_with_index do |val, index|
			val.y -= speed[index]
			if val.y <= -val.radius
				speed.delete_at(index)
				speed.insert(index, rand(1.0..3.0))
				val.radius = rand(10.0..18.0)
				val.x, val.y, val.new_colour = rand(val.radius..$width - val.radius), $height, "##{SecureRandom.hex(3)}"
				val.opacity = rand(0.3..0.8)
			end
		end
	end
	show
end

main
