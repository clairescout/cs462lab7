ruleset wovyn_base{
  meta {
    use module lab2_twilio alias twilio
    use module sensor_profile
    use module io.picolabs.subscription alias Subscriptions
    shares __testing, get_temp_threshold
    provides get_temp_threshold
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "temp", "baro" ] },
                              { "domain": "wovyn", "type": "new_temperature_reading",
                                          "attrs": [ "temperature", "timestamp" ] } ] }
    from_phonenumber = 8015152998

  }

  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing") != null
    pre {
      genericThing = event:attr("genericThing").decode()
    }
    send_directive("GenericThing exists")
    fired {
      raise wovyn event "new_temperature_reading"
        attributes {"temperature": genericThing{"data"}{"temperature"}.decode()[0]{"temperatureF"}, "timestamp": time:now()}
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attr("temperature")
      timestamp = event:attr("timestamp")
      subscription = Subscriptions:established()[0].klog()
    }
    if temperature > sensor_profile:temperature_threshold() then
      event:send(
        { "eci": subscription{"Tx"}, "eid": "threshold_violation",
          "domain": "wovyn", "type": "threshold_violation",
          "attrs": {"temperature": temperature, "timestamp": timestamp}}
      );
    //   send_directive("Temperature above threshold")
    // fired {
    //   raise wovyn event "threshold_violation"
    //     attributes {"temperature": temperature, "timestamp": timestamp}
    // }
  }

  rule threshold_violation {
    select when wovyn threshold_violation
    pre {
      temperature = event:attr("temperature")
    }
    twilio:sendMessage(sensor_profile:to_phonenumber(), from_phonenumber,
        ("Temperature Violation: The temperature exceeds " + sensor_profile:temperature_threshold() + ". Temperature is " + temperature + " degrees Farenheit."))
  }

}
