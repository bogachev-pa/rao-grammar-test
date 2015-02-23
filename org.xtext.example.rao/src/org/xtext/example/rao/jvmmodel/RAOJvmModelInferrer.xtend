package org.xtext.example.rao.jvmmodel

import com.google.inject.Inject
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import org.eclipse.xtext.naming.IQualifiedNameProvider

import org.xtext.example.rao.rAO.ResourceType
import org.xtext.example.rao.rAO.ResourceDeclaration
import org.xtext.example.rao.rAO.RAOModel
import org.eclipse.xtext.naming.QualifiedName

class RAOJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension JvmTypesBuilder

	@Inject extension IQualifiedNameProvider

	def dispatch void infer(
		RAOModel element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase
	) {
		acceptor.accept(element.toClass(QualifiedName.create("db"))) [
			for (entity : element.objects) {
				switch entity {
					ResourceDeclaration: {
						val resource = element.toField(
							entity.name,
							entity.reference.class.typeRef()
						)
						members += resource
					}
				}
			}
		]
		for (entity : element.objects) {
			switch entity {
				ResourceType: {
					acceptor.accept(entity.toClass(entity.fullyQualifiedName)) [
						members += entity.toField("name", String.typeRef)
						for (param : entity.params) {
							members += entity.toField(
								param.variable.name,
								param.variable.parameterType
							)[initializer = param.right]
							members += entity.toSetter(
								param.variable.name,
								param.variable.parameterType
							)
							members += entity.toGetter(
								param.variable.name,
								param.variable.parameterType
							)
						}
					]
				}
			}
		}
	}
}
