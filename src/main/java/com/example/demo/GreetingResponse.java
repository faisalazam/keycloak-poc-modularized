package com.example.demo;

import java.util.List;

// Simple DTO for structured response
public record GreetingResponse(String message, String username, List<String> roles) {
}
