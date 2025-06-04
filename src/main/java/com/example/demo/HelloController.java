package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
public class HelloController {

    private static final Logger logger = LoggerFactory.getLogger(HelloController.class);

    @GetMapping("/public")
    public GreetingResponse publicEndpoint() {
        logger.info("Accessed public endpoint");
        return new GreetingResponse("This is a public endpoint.", null, null);
    }

    @GetMapping("/hello")
    public GreetingResponse hello(Principal principal, Authentication authentication) {
        if (principal == null) {
            logger.warn("Unauthenticated access attempt to /hello");
            return new GreetingResponse("Hello, anonymous!", null, null);
        }

        final List<String> roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        logger.info("Authenticated user '{}' accessed /hello with roles {}", principal.getName(), roles);

        return new GreetingResponse(
                "Hello, " + principal.getName() + "!",
                principal.getName(),
                roles
        );
    }
}
