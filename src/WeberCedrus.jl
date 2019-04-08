module WeberCedrus

using PyCall
export Cedrus

using Weber
import Weber: keycode, iskeydown, iskeyup, addtrial, addpractice, poll_events
import Base: hash, isless, ==, show

mutable struct Cedrus <: Weber.Extension
  devices::PyObject
  trial_start::Float64
end

function InitExtension()
  pyxid = pyimport_conda("pyxid","pyxid","haberdashPI")
  pyxid[:use_response_pad_timer] = true
  cedrus = Cedrus(pyxid[:get_xid_devices](),0.0)
  for dev in cedrus.devices
    if dev[:is_response_device]()
      dev[:reset_base_timer]()
    end
  end
  cedrus
end

@Weber.event struct CedrusDownEvent <: Weber.ExpEvent
  code::Int
  port::Int
  time::Float64
end


@Weber.event struct CedrusUpEvent <: Weber.ExpEvent
  code::Int
  port::Int
  time::Float64
end

struct CedrusKey <: Weber.Key
  code::Int
end

# make sure the cedrus keys have a well defined ordering
hash(x::CedrusKey,h::UInt) = hash(CedrusKey,hash(x.code,h))
==(x::CedrusKey,y::CedrusKey) = x.code == y.code
isless(x::CedrusKey,y::CedrusKey) = isless(x.code,y.code)

# make sure cedrus keys are displayed in a easily readable form
function show(io::IO,x::CedrusKey)
  if 0 <= x.code <= 19
    write(io,"key\":cedrus$(x.code):\"")
  else
    write(io,"Weber.CedrusKey($(x.code))")
  end
end

merge!(Weber.str_to_code,Dict(":cedrus$i:" => CedrusKey(i) for i in 0:19))

keycode(e::CedrusDownEvent) = CedrusKey(e.code)
keycode(e::CedrusUpEvent) = CedrusKey(e.code)

iskeydown(event::CedrusDownEvent) = true
iskeydown(key::CedrusKey) = e -> iskeydown(e,key::CedrusKey)
iskeydown(event::CedrusDownEvent,key::CedrusKey) = event.code == key.code

iskeyup(event::CedrusUpEvent) = true
iskeyup(key::CedrusKey) = e -> iskeydown(e,key)
iskeyup(event::CedrusUpEvent,key::CedrusKey) = event.code == key.code

time(e::CedrusUpEvent) = e.time
time(e::CedrusDownEvent) = e.time

function reset_response(cedrus::Cedrus)
  old_len = length(cedrus.devices)
  cedrus.devices = pyxid[:get_xid_devices]()
  if old_len != length(cedrus.devices)
    warn("The number of available Cedrus devices changed from $old_len to "*
         "$(length(cedrus.devices)) in the middle of an experiment!")
  end

  for dev in cedrus.devices
    if dev[:is_response_device]()
      dev[:reset_rt_timer]()
    end
  end
  cedrus.trial_start = Weber.tick()
end

function addtrial(e::ExtendedExperiment{Cedrus},moments...)
  addtrial(next(e),moment(reset_response,extension(e)),moments...)
end

function addpractice(e::ExtendedExperiment{Cedrus},moments...)
  addpractice(next(e),moment(reset_response,extension(e)),moments...)
end

function poll_events(callback::Function,exp::ExtendedExperiment{Cedrus},time::Float64)
  poll_events(callback,next(exp),time)
  for dev in extension(exp).devices
    if dev[:is_response_device]()
      dev[:poll_for_response]()
      while dev[:response_queue_size]() > 0
        resp = dev[:get_next_response]()
        if resp["pressed"]
          callback(exp,
                   CedrusDownEvent(resp["key"],resp["port"],
                                   resp["time"] + extension(exp).trial_start))
        else
          callback(exp,
                   CedrusUpEvent(resp["key"],resp["port"],
                                 resp["time"] + extension(exp).trial_start))
        end
      end
    end
  end
end

end
