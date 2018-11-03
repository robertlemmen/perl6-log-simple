unit module Log::Simple;

enum Severity (
    TRACE => 0,
    DEBUG => 1,
    INFO => 2,
    WARN => 3,
    ERROR => 4
);

my $date-fmt = sub ($self) {
    given $self {
        sprintf "%04d-%02d-%02d %02d:%02d:%06.3f",
            .year, .month, .day,
            .hour, .minute, .second
    }
}

role LogHandler {
    has $.parent-handler;
    method handle-log(Instant $timestamp, Severity $severity, $context, $message) {
        ...
    }
    method propagate-log(Instant $timestamp, Severity $severity, $context, $message) {
        if self.handle-log($timestamp, $severity, $context, $message) {
            if $!parent-handler {
                $!parent-handler.propagate-log($timestamp, $severity, $context, $message);
            }
        }
    }
}

class SimpleConsoleAppender does LogHandler {
    # XXX formatter specs
    # XXX time as utc?
    method handle-log(Instant $timestamp, Severity $severity, $context, $message) {
        say   DateTime.new($timestamp, formatter => $date-fmt)
            ~ " ["
            ~ sprintf('%-6s', $context)
            ~ "] ["
            ~ sprintf('%-5s', $severity) ~ "] $message";
        return True;
    }
}

class SeverityFilter does LogHandler {
    has Severity $.threshold;
    method handle-log(Instant $timestamp, Severity $severity, $context, $message) {
        return $severity >= $!threshold;
    }
}

class Logger {

    has $.context;
    has $.handler;

    method trace($msg) {
        $!handler.propagate-log(now, TRACE, $!context, $msg);
    }

    method debug($msg) {
        $!handler.propagate-log(now, DEBUG, $!context, $msg);
    }

    method info($msg) {
        $!handler.propagate-log(now, INFO, $!context, $msg);
    }

    method warn($msg) {
        $!handler.propagate-log(now, WARN, $!context, $msg);
    }

    method error($msg) {
        $!handler.propagate-log(now, ERROR, $!context, $msg);
    }
}

my $default-log-setup = SeverityFilter.new(threshold => DEBUG, parent-handler => SimpleConsoleAppender.new(parent-handler => Nil));

# XXX access to the global above, to set it to other setups

sub make-logger($context) is export {
    return Logger.new(context => $context, handler => $default-log-setup);
}
