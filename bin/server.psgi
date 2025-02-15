# -*- perl -*-
use strict;
use warnings;
use Path::Tiny;
use Wanage::URL;
use Wanage::HTTP;
use Warabe::App;
use Promised::Command;

$ENV{LANG} = 'C';
$ENV{TZ} = 'UTC';

my $RootPath = path (__FILE__)->parent->parent->absolute;

return sub {
  delete $SIG{CHLD} if defined $SIG{CHLD} and not ref $SIG{CHLD}; # XXX

  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);

  return $app->execute_by_promise (sub {
    my $path = [@{$app->path_segments}];

    $http->set_response_header
        ('Strict-Transport-Security' => 'max-age=10886400; includeSubDomains; preload');

    if ((@$path == 1 and $path->[0] eq '') or
        (@$path == 2 and $path->[0] eq 'gate' and $path->[1] eq 'cvs')) {
      $app->http->set_status (302);
      $app->http->set_response_header ('location', '/gate/cvs/');
      return $app->throw;
    } elsif (@$path >= 4 and $path->[0] eq 'gate' and $path->[1] eq 'viewvc' and $path->[2] eq 'statics') {
      $path->[1] = 'cvs';
      $path->[2] = '*docroot*';
    }
    if (@$path >= 3 and $path->[0] eq 'gate' and $path->[1] eq 'cvs') {
      shift @$path;
      shift @$path;
      
      my $redirect = 0;
      if ($path->[0] eq '*checkout*') {
        splice @$path, 1, 0, ('suikacvs');
        $redirect = 1;
      } elsif ($path->[0] eq '*docroot*') {
        #
      } elsif ($path->[0] eq 'melon') {
        shift @$path;
      } else {
        unshift @$path, 'suikacvs';
        $redirect = 1;
      }
      if ($path->[0] eq 'suikacvs') {
        if (@$path >= 2 and $path->[1] eq 'suikawiki') {
          $path->[0] = 'pub';
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/newsportal/	http://suika.fam.cx/gate/cvs/messaging/newsportal/
        if (@$path >= 2 and $path->[1] eq 'newsportal') {
          splice @$path, 1, 0, ('messaging');
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/perl/lib/Char/InSet/	http://suika.fam.cx/gate/cvs/perl/charclass/lib/Char/Class/
        if (@$path >= 5 and $path->[1] eq 'perl' and $path->[2] eq 'lib' and $path->[3] eq 'Char' and $path->[4] eq 'InSet') {
          $path->[4] = 'Class';
          splice @$path, 2, 0, ('charclass');
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/perl/lib/Char/	http://suika.fam.cx/gate/cvs/perl/charclass/lib/Char/
        if (@$path >= 4 and $path->[1] eq 'perl' and $path->[2] eq 'lib' and $path->[3] eq 'Char') {
          splice @$path, 2, 0, ('charclass');
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/perl/lib/Message/	http://suika.fam.cx/gate/cvs/messaging/manakai/lib/Message/
        if (@$path >= 4 and $path->[1] eq 'perl' and $path->[2] eq 'lib' and $path->[3] eq 'Message') {
          splice @$path, 2, 1, ('messaging', 'manakai');
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/perl/web/Message-pm/	http://suika.fam.cx/gate/cvs/messaging/manakai/doc/
        if (@$path >= 4 and $path->[1] eq 'perl' and $path->[2] eq 'web' and $path->[3] eq 'Message-pm') {
          $path->[1] = 'messaging';
          $path->[2] = 'manakai';
          $path->[3] = 'doc';
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/tool/bunshin/	http://suika.fam.cx/gate/cvs/messaging/bunshin/
        #Redirect 301 /gate/cvs/tool/suikawari/	http://suika.fam.cx/gate/cvs/messaging/suikawari/
        if (@$path >= 3 and $path->[1] eq 'tool' and ($path->[2] eq 'bunshin' or $path->[2] eq 'suikawari')) {
          $path->[1] = 'messaging';
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/tool/iemenu/	http://suika.fam.cx/gate/cvs/www/ie/iemenu/
        if (@$path >= 3 and $path->[1] eq 'tool' and $path->[2] eq 'iemenu') {
          splice @$path, 1, 1, ('www', 'ie');
          $redirect = 1;
        }
        #Redirect 301 /gate/cvs/wakaba/wiki/SuikaWiki/ http://suika.fam.cx/gate/cvs/suikawiki/script/lib/SuikaWiki/
        if (@$path >= 4 and $path->[1] eq 'wakaba' and $path->[2] eq 'wiki' and $path->[3] eq 'SuikaWiki') {
          splice @$path, 1, 2, ('suikawiki', 'script', 'lib');
          $redirect = 1;
        }
      } # suikacvs
      if ($redirect) {
        my $url = '/'.(join '/', map { percent_encode_c $_ } 'gate', 'cvs', 'melon', @$path);
        $url .= '?' . $app->http->url->{query}
            if defined $app->http->url->{query};
        $app->http->set_status (302);
        $app->http->set_response_header ('location', $url);
        return $app->throw;
      }
      my $cmd = Promised::Command->new (['python', $RootPath->child ("local/bin/viewvc.cgi")]);
      $cmd->envs->{REQUEST_METHOD} = $app->http->request_method;
      $cmd->envs->{QUERY_STRING} = $app->http->original_url->{query};
      $cmd->envs->{CONTENT_LENGTH} = $app->http->request_body_length;
      $cmd->envs->{CONTENT_TYPE} = $app->http->get_request_header ('Content-Type');
      $cmd->envs->{HTTP_ACCEPT_LANGUAGE} = $app->http->get_request_header ('Accept-Language');
      $cmd->envs->{PATH_INFO} = join '/', '', @$path;
      $cmd->envs->{SCRIPT_NAME} = '/gate/cvs/melon';
      $cmd->envs->{PYTHONPATH} = 'local/viewvc/lib/';
      $cmd->stdin ($app->http->request_body_as_ref);
      my $stdout = '';
      my $out_mode = '';
      my $cgi_error;
      $cmd->stdout (sub {
        if ($out_mode eq 'body') {
          $app->http->send_response_body_as_ref (\($_[0]));
          return;
        }
        $stdout .= $_[0];
        while ($stdout =~ s/^([^\x0A]*[^\x0A\x0D])\x0D?\x0A//) {
          my ($name, $value) = split /:/, $1, 2;
          $name =~ tr/A-Z/a-z/;
          if (not defined $value) {
            warn "Bad CGI output: |$name|\n";
            $cgi_error = 1;
          } elsif ($name eq 'status') {
            my ($code, $reason) = split /\s+/, $value, 2;
            $app->http->set_status ($code, reason_phrase => $reason);
          } else {
            $app->http->set_response_header ($name => $value);
          }
        }
        if ($stdout =~ s/^\x0D?\x0A//) {
          $out_mode = 'body';
          $app->http->send_response_body_as_ref (\$stdout);
        }
      });
      $cmd->timeout (60);
      $cmd->timeout_signal ('KILL');
      return $cmd->run->then (sub {
        return $cmd->wait;
      })->then (sub {
        die $_[0] unless $_[0]->exit_code == 0;
        die "CGI output error" if $cgi_error;
        $app->http->close_response_body;
      });
    }

    return $app->send_error (404);
  });
};

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
