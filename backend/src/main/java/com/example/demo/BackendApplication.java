package com.example.demo;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
public class BackendApplication {


	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

	@Bean
	CommandLineRunner initData(CompanyRepository companyRepository, UserRepository userRepository, PasswordEncoder passwordEncoder) {
		return args -> {
			if (companyRepository.count() == 0) {
				Company c1 = new Company();
				c1.setName("Rich");
				c1.setUid("rich");
				companyRepository.save(c1);
			}

			if (userRepository.count() == 0) {
				User u1 = new User();
				u1.setUsername("admin");
				u1.setPassword(passwordEncoder.encode("adminpass"));
				u1.setRole(User.Role.ADMIN);
				userRepository.save(u1);

				User u2 = new User();
				u2.setUsername("alice");
				u2.setPassword(passwordEncoder.encode("alicepass"));
				u2.setRole(User.Role.CLIENT);
				u2.setCompany(companyRepository.findAll().get(0));
				userRepository.save(u2);
			}
		};
	}
}