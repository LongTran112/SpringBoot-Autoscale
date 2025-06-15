package com.company.autoscale.controller;


import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MetricsController {

    private final Counter customCounter;

    public MetricsController(MeterRegistry registry) {
        this.customCounter = Counter.builder("custom_metric")
                .description("Custom metric counter")
                .register(registry);
    }

    @GetMapping("/increment")
    public String increment() {
        customCounter.increment();
        return "Counter incremented!";
    }
}