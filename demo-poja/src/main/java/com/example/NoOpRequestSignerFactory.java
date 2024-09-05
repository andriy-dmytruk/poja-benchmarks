package com.example;

import com.oracle.bmc.Service;
import com.oracle.bmc.auth.AbstractAuthenticationDetailsProvider;
import com.oracle.bmc.http.signing.RequestSigner;
import com.oracle.bmc.http.signing.RequestSignerFactory;
import io.micronaut.core.annotation.Nullable;
import jakarta.annotation.Nonnull;
import jakarta.inject.Singleton;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Singleton
public class NoOpRequestSignerFactory implements RequestSignerFactory {

    @Override
    public RequestSigner createRequestSigner(Service service, AbstractAuthenticationDetailsProvider abstractAuthProvider) {

        return new RequestSigner() {
            @Override
            public @Nonnull Map<String, String> signRequest(
                    @Nonnull URI uri, @Nonnull String httpMethod,
                    @Nonnull Map<String, List<String>> headers, @Nullable Object body
            ) {
                return Map.of();
            }
        };

    }

}