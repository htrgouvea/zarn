package Zarn::Network::DataFlow {
    use strict;
    use warnings;
    use Getopt::Long;
    use Zarn::Component::Engine::TaintTracker;
    use Zarn::Component::Engine::DefUseAnalyzer;
    use Zarn::Component::Engine::CallGraphBuilder;
    use Zarn::Component::Engine::AliasAnalyzer;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($syntax_tree, $file);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'  => \$syntax_tree,
            'file=s' => \$file
        );

        if ($syntax_tree && $file) {
            my $def_use_analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([
                '--ast' => $syntax_tree,
            ]);

            my $taint_tracker = Zarn::Component::Engine::TaintTracker -> new([
                '--def_use_analyzer' => $def_use_analyzer,
            ]);

            $def_use_analyzer -> {set_taint_tracker} -> ($taint_tracker);

            my $call_graph_builder = Zarn::Component::Engine::CallGraphBuilder -> new([
                '--file' => $file,
            ]);

            my $alias_analyzer = Zarn::Component::Engine::AliasAnalyzer -> new([
                '--ast'              => $syntax_tree,
                '--def_use_analyzer' => $def_use_analyzer,
            ]);

            my $network = {
                def_use_analyzer   => $def_use_analyzer,
                taint_tracker      => $taint_tracker,
                call_graph_builder => $call_graph_builder,
                alias_analyzer     => $alias_analyzer,
                build_network => sub {
                    $def_use_analyzer -> {build_chains} -> ();
                    $alias_analyzer -> {analyze} -> ();

                    return;
                },
            };

            return $network;
        }

        return 0;
    }
}

1;
