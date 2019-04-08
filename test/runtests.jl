using Weber
using WeberCedrus
using Base.Test

# these tests are copied from Weber, and merely verify that ane expeirment still
# runs properly with the extension installed.

# this allows a test of timing for an experiment without setting up any
# multimedia resources, so it can be run just about anywhere.
function find_timing(fn;keys...)
  empty!(Weber.null_record)
  exp = Experiment(;null_window=true,hide_output=true,extensions=[CedrusXID()],keys...)
  setup(() -> fn(),exp)
  run(exp,await_input=false)

  nostarts = filter(x -> !endswith(string(x[:code]),"_start") &&
                         x[:code] != "terminated",
                    Weber.null_record)
  map(x -> x[:code],nostarts),map(x -> x[:time],nostarts),nostarts
end


seq_events,_,_ = find_timing() do
  addtrial(moment(0.01,() -> record(:a)),
           moment(0.01,() -> record(:b)),
           moment(0.01,() -> record(:c)))
end

@testset "Moment Sequencing" begin
  @test seq_events == [:a,:b,:c]
end
