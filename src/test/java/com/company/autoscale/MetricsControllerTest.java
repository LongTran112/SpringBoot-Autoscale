package com.company.autoscale;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.company.autoscale.controller.MetricsController;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(MetricsController.class)
class MetricsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @InjectMocks
    private MeterRegistry meterRegistry;

    @InjectMocks
    private Counter counter;

    @Test
    void incrementEndpoint_shouldIncrementCounter() throws Exception {
        // Setup mock behavior
        Mockito.when(meterRegistry.counter("custom_metric")).thenReturn(counter);

        // Test endpoint
        mockMvc.perform(get("/increment"))
                .andExpect(status().isOk())
                .andExpect(content().string("Counter incremented!"));

        // Verify counter was incremented
        Mockito.verify(counter, Mockito.times(1)).increment();
    }
}