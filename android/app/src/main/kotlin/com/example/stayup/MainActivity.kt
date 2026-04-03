package com.stayup.schedule

import android.os.Bundle
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.Button
import top.yukonga.miuix.kmp.basic.ButtonDefaults
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.Icon
import top.yukonga.miuix.kmp.basic.Text
import top.yukonga.miuix.kmp.basic.TextButton
import top.yukonga.miuix.kmp.icon.MiuixIcons
import top.yukonga.miuix.kmp.icon.extended.Backup
import top.yukonga.miuix.kmp.icon.extended.Tasks
import top.yukonga.miuix.kmp.icon.extended.Theme
import top.yukonga.miuix.kmp.theme.ColorSchemeMode
import top.yukonga.miuix.kmp.theme.MiuixTheme
import top.yukonga.miuix.kmp.theme.ThemeController

class MainActivity : ComponentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		val composeView = ComposeView(this).apply {
			layoutParams = FrameLayout.LayoutParams(
				FrameLayout.LayoutParams.MATCH_PARENT,
				FrameLayout.LayoutParams.MATCH_PARENT,
			)
			setContent {
				StayUpMiuixApp()
			}
		}

		setContentView(composeView)
	}
}

private data class LauncherSection(
	val title: String,
	val summary: String,
	val icon: ImageVector,
)

@Composable
private fun StayUpMiuixApp() {
	val controller = remember {
		ThemeController(
			ColorSchemeMode.MonetSystem,
			keyColor = Color(0xFF4ECDC4),
		)
	}

	MiuixTheme(controller = controller) {
		val sections = remember {
			listOf(
				LauncherSection(
					title = "课程表首页",
					summary = "把周视图、课程卡片和快速入口迁到 MIUIX 组件层。",
					icon = MiuixIcons.Tasks,
				),
				LauncherSection(
					title = "课程编辑",
					summary = "后续把表单、验证和弹窗交互逐步迁移到原生 Android 侧。",
					icon = MiuixIcons.Theme,
				),
				LauncherSection(
					title = "导入导出",
					summary = "把文件选择、分享和本地文件访问继续沿用现有数据契约。",
					icon = MiuixIcons.Backup,
				),
			)
		}
		var selectedSection by remember { mutableIntStateOf(0) }
		val selected = sections[selectedSection]

		Column(
			modifier = Modifier
				.fillMaxSize()
				.background(MiuixTheme.colorScheme.background)
				.padding(20.dp),
			verticalArrangement = Arrangement.spacedBy(16.dp),
		) {
			Card(
				modifier = Modifier.fillMaxWidth(),
				insideMargin = androidx.compose.foundation.layout.PaddingValues(20.dp),
			) {
				Text(
					text = "StayUP Android Rewrite",
					style = MiuixTheme.textStyles.title1,
					color = MiuixTheme.colorScheme.onBackground,
				)
				Spacer(modifier = Modifier.height(8.dp))
				Text(
					text = "This launcher is now backed by a native Compose / Miuix shell on Android.",
					style = MiuixTheme.textStyles.body1,
					color = MiuixTheme.colorScheme.onSurfaceVariantSummary,
				)
			}

			Card(
				modifier = Modifier.fillMaxWidth(),
				insideMargin = androidx.compose.foundation.layout.PaddingValues(20.dp),
			) {
				Text(
					text = "Migration targets",
					style = MiuixTheme.textStyles.subtitle,
					color = MiuixTheme.colorScheme.onBackground,
				)
				Spacer(modifier = Modifier.height(12.dp))
				Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
					sections.forEachIndexed { index, item ->
						TextButton(
							text = item.title,
							onClick = { selectedSection = index },
							modifier = Modifier.weight(1f),
							colors = if (selectedSection == index) {
								ButtonDefaults.textButtonColorsPrimary()
							} else {
								ButtonDefaults.textButtonColors()
							},
						)
					}
				}
			}

			Card(
				modifier = Modifier.fillMaxWidth(),
				insideMargin = androidx.compose.foundation.layout.PaddingValues(20.dp),
			) {
				Row(
					verticalAlignment = Alignment.CenterVertically,
				) {
					Icon(
						imageVector = selected.icon,
						contentDescription = null,
						tint = MiuixTheme.colorScheme.primary,
					)
					Spacer(modifier = Modifier.width(12.dp))
					Column(modifier = Modifier.weight(1f)) {
						Text(
							text = selected.title,
							style = MiuixTheme.textStyles.title2,
							color = MiuixTheme.colorScheme.onBackground,
						)
						Spacer(modifier = Modifier.height(4.dp))
						Text(
							text = selected.summary,
							style = MiuixTheme.textStyles.body1,
							color = MiuixTheme.colorScheme.onSurfaceVariantSummary,
						)
					}
				}

				Spacer(modifier = Modifier.height(16.dp))
				Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
					Button(
						onClick = { selectedSection = 0 },
						modifier = Modifier.weight(1f),
					) {
						Text("Start with Home")
					}
					Button(
						onClick = { selectedSection = 1 },
						modifier = Modifier.weight(1f),
					) {
						Text("Open Editor")
					}
				}

				Spacer(modifier = Modifier.height(8.dp))
				Box(modifier = Modifier.fillMaxWidth()) {
					TextButton(
						text = "Review import/export shell",
						onClick = { selectedSection = 2 },
					)
				}
			}

			Card(
				modifier = Modifier
					.fillMaxWidth()
					.widthIn(max = 560.dp),
				insideMargin = androidx.compose.foundation.layout.PaddingValues(20.dp),
			) {
				Text(
					text = "Next step: migrate the schedule page into a native Android screen and connect it to the existing persistence contract.",
					style = MiuixTheme.textStyles.body2,
					color = MiuixTheme.colorScheme.onSurfaceVariantSummary,
				)
			}
		}
	}
}
