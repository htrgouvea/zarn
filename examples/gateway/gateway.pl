#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use Mojo::URL;
use Mojolicious::Lite -signatures;
use Mojo::File;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;

get "*" => sub ($request) {
    my $confs = Mojo::File -> new("config.json");

    if ($confs) {
        my $json_list = $confs -> slurp();
        my $full_list = decode_json($json_list);

        foreach my $value ($full_list) {
            my $full_request = $request -> req();
            my $url_values   = $full_request -> url;
            my $url_parsing  = Mojo::URL -> new($url_values);

            if ($url_parsing =~ $value -> {base_path} . $value -> {route}) {
                my $userAgent = Mojo::UserAgent -> new();

                my $endpoint = $value -> {scheme} . $value -> {host} . ":" . $value -> {port} . $value -> {endpoint};
                
                my $gateway = $userAgent -> get($endpoint) -> result();
                
                return ($request -> render (
                    text => $gateway -> body(),
                    status => $gateway -> code()
                ));
            }
        }
    }

    return ($request -> render (
        text => "Some thing as wrong... =/"
    ));
};

app -> start();






    # url
        # base
            # scheme
            # host
            # port
        # path
            # path
        # query 
            # string
    

    # $request -> req -> content -> headers
    # $request -> req -> content -> 