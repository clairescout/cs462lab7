ruleset threshold_violation_manager {
  meta {
    use module lab2_keys
    use module twilio alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  }

  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "test", "type": "send_sms",
                  "attrs": [ "to", "from", "message" ] } ] };
    phoneNumber = 8017353755
    fromNumber = 8015152998

    send_sms = defaction(message) {
      twilio:send_sms(phoneNumber,fromNumber, message );
    }

  }

  rule threshold_violation {
    select when wovyn threshold_violation
    pre {
      temperature = event:attr("temperature")
      timestamp = event:attr("timestamp")
      message = "Temperature Violation at " + timestamp + ". Temperature is " + temperature + " degrees Farenheit."
    }
    send_sms(message);

  }

}
