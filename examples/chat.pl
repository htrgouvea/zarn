#!/usr/bin/env perl

use DateTime;
use Mojolicious::Lite;
use Data::Dumper qw(Dumper);

my %clients;

get '*' => sub {  
    my $content = shift;

    $content->res->headers->header('Access-Control-Allow-Origin' => 'heitorgouvea.me');
    $content->res->headers->header('Access-Control-Allow-Methods' => 'GET, OPTIONS, POST, DELETE, PUT');

    $content -> render(text => 'Hello World!');
};

websocket '/chat' => sub {
    my $content = shift;

    $content->res->headers->header('Access-Control-Allow-Origin' => 'heitorgouvea.me');
    $content->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $content->res->headers->header('Access-Control-Allow-Methods' => 'GET, OPTIONS, POST, DELETE, PUT');
    $content->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type');
    $content->res->headers->header('Access-Control-Max-Age' => '1728000');
  
    my $tx_id = sprintf "%s", $content->tx;
    $clients{$tx_id} = { ws => $content->tx };

    $content->on(json => sub {
        my ($ws, $hash) = @_;
        $content->app->log->debug("From $ws received " . Dumper $hash);

        if ($hash->{heartbeat}) {
            $ws->send({json => {heartbeat => $hash->{heartbeat}}});
            return;
        }

        my $dt = DateTime -> now (time_zone => 'Asia/Tokyo');

        if ($hash -> {login}) {
            $clients{$tx_id}{user_name} = $hash->{login};
            $ws->send({json => {login => 'ok'}});
            
            foreach my $ws (keys %clients) {
                next if $ws eq $tx_id;
                $clients{$ws}{ws}->send({json => {
                    msg => $dt->hms . " $clients{$tx_id}{user_name} has joined the conversation"
                }});
            }

            return;
        }

        foreach my $ws (keys %clients) {
            my $msg = $dt->hms . ($ws eq $tx_id ? " $hash->{msg}" : " $clients{$tx_id}{user_name}: $hash->{msg}");
            
            $clients{$ws}{ws}->send({json => {
                msg => $msg,
            }});
        }

        return;
    });

    $content -> on(finish => sub {
        my ($ws, $code, $reason) = @_;
        $content->app->log->debug( "Finished $ws Code $code reason: '" . ( $reason // '' ) .  "'");

        my $dt   = DateTime->now( time_zone => 'Asia/Tokyo');

        foreach my $ws (keys %clients) {
            next if $ws eq $tx_id;

            $clients{$ws}{ws}->send({json => {
                msg => $dt->hms . " $clients{$tx_id}{user_name} has left the conversation"
            }});
        }

        delete $clients{$ws};

        return;
    });
};

get '/' => 'index';
app -> start();

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>Chat</title>
    <script>
        var ws;
        var user_name;
        var heartbeat_interval = null;
        function login(e) {
            if (e.keyCode !== 13) {
                  return false;
            }
            user_name = document.getElementById('name').value;
            //console.log(user_name);
            document.getElementById('login_name').innerHTML = user_name;
            document.getElementById('login').style.display = 'none';
            document.getElementById('chat').style.display = 'block';

            setup();
        }

        function setup() {
            ws = new WebSocket('<%= url_for('chat')->to_abs %>');

            ws.onmessage = function (event) {
                var data = JSON.parse(event.data);
                if (! data.msg) {
                    return;
                }
                console.log('Received', data.msg);
                document.getElementById('output').innerHTML = data.msg + '<br>' + document.getElementById('output').innerHTML;
            };

            ws.onopen = function (event) {
                ws.send(JSON.stringify({login: user_name}));

                // heartbeat: not based on http://django-websocket-redis.readthedocs.io/en/latest/heartbeats.html
                if (heartbeat_interval === null) {
                    heartbeat_interval = setInterval(function() {
                        ws.send(JSON.stringify({heartbeat: user_name}));
                    }, 14000);
                }
            };

            ws.onclose = function(){
                if (heartbeat_interval !== null) {
                    clearInterval(heartbeat_interval);
                }
                setTimeout(setup, 1000);
            };
        };

        function send(e) {
            if (e.keyCode !== 13) {
                  return false;
            }
            var msg = document.getElementById('msg').value;
            document.getElementById('msg').value = '';
            console.log('send', msg);
            ws.send(JSON.stringify({msg: msg}));
        }
        
        function onload() {
            //console.log('onload');
            document.getElementById('name').addEventListener('keypress', login);
            document.getElementById('msg').addEventListener('keypress', send);
            document.getElementById('msg').focus();
        }
    </script>

    <style>
      #chat {
        display: none;
      }
    </style>
  </head>
  <body onload="onload()">
    <div id="login">Your name: <input type="text" id="name"></div>
    <div id="chat">
        Logged in as <span id="login_name"></span><br>
        <input type="text" id="msg" placeholder="Your message">
        <div id="output"></div>
    </div>
  </body>
</html>