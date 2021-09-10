# frozen_string_literal: true

desc 'Test docker images'
task :test do
  puts '*** Testing images ***'.green
  $images.each do |image|
    # basic container test
    begin
      puts "Running tests on #{image.build_tag}".green
      container = `docker run --rm --health-interval=2s -d -p 8080 #{image.build_tag}`.strip

      # wait for container state "running"
      state = ''
      printf 'Waiting for container startup'
      10.times do
        state = `docker inspect --format='{{.State.Status}}' #{container}`.strip
        break if state == 'running'
        printf "."
        sleep 1
      end
      puts
      if state != 'running'
        puts "Container failed to reach \"running\" state. Got \"#{state}\"".red
        exit 1
      end

      # if the container has a health check, wait for it to
      container_health = `docker inspect --format='{{.State.Health}}' #{container}`.strip
      hashealth = container_health == "<nil>" ? false : true
      if hashealth
        printf 'Waiting for container healthy'
        health_status = ''
        20.times do
          health_status = `docker inspect --format='{{.State.Health.Status}}' #{container}`.strip
          break if health_status == 'healthy'
          printf "."
          sleep 1
        end
        puts
        if health_status != 'healthy'
          puts "Container failed to reach \"healthy\" status. Got \"#{health_status}\"".red
          exit 1
        end
      end
      # end of basic container test

      # Nginx function test
      # get local forwarded port (random)
      forwarded_port = `docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostPort}} {{end}}' #{container}`.strip
      cmd = "curl -qs http://localhost:#{forwarded_port}/ping"
      puts cmd
      response = `#{cmd}`
      puts response
      unless response == 'pong'
        puts "Received unexpected response \"#{response}\", expected \"pong\".".red
        exit 1
      end

    # end of container tests
  ensure
    sh "docker kill #{container}"
  end
  puts "Testing image #{image.build_tag} successful.".green
end
end
