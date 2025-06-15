package com.company.autoscale.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import io.micrometer.core.annotation.Timed;

@RestController
public class HelloController {

    @GetMapping("/")
    @Timed(value = "hello.request", description = "Time taken for hello endpoint")
    public String hello() {
        return "Hello from Spring Boot!";
    }

    @GetMapping("/api")
    @Timed(value = "api.request", description = "Time taken for api endpoint")
    public String api() {
        return "API Response";
    }
}
