# frozen_string_literal: true

desc 'Test docker images'
task :test do
  puts '*** Testing images ***'.green
  $images.each do |image|
    puts "Running tests on #{image.build_tag}"
    container = `docker run --rm --health-interval=1s -d -p 8080 #{image.build_tag}`.strip
    delay_seconds = 1
    printf "Waiting for container startup"
    100.times do
      status = `docker inspect --format='{{json .State.Health.Status}}' #{container}`.strip
      break if status != '"starting"'
      sleep(delay_seconds)
    end
    puts
    begin
      sh "docker exec #{container} /usr/bin/printf 'hello from #{image.build_tag}\'"
      puts
      cmd = "curl -qs http://localhost:8080/ping"
      puts cmd
      response = `#{cmd}`
      puts response
      unless response == 'pong'
        puts "Received unexpected response \"#{response}\", expected \"pong\".".red
        exit 1
      end
    ensure
      sh "docker kill #{container}"
      sh d
    end
  end
end
