package com.woundify;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class WoundifyApplication {

    public static void main(String[] args) {
        SpringApplication.run(WoundifyApplication.class, args);
    }

    @Bean
    WoundifyStore woundifyStore() {
        return new WoundifyStore();
    }
}
